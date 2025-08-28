# app.py
# This script runs the main Flask backend server for the JawiAI application.
# It handles API requests, performs information retrieval using a priority-based
# system (Exact Match > Semantic Search), and interacts with the Qwen LLM API
# to generate context-aware responses.

import json
import os
import numpy as np
import requests
import faiss
from flask import Flask, jsonify, request
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv

# Load API Key From .env
load_dotenv()
app = Flask(__name__)

# CONFIGURATION
# Defines the constants used to connect to the LLM API.
QWEN_API_URL = "https://litellm.bangka.productionready.xyz/v1/chat/completions"
MODEL_NAME = "vllm-qwen3"
QWEN_API_KEY = os.getenv("QWEN_API_KEY")
if not QWEN_API_KEY:
    raise ValueError("API Key (QWEN_API_KEY) was not found. Please set it as an environment variable.")

# A threshold for FAISS L2 distance. Search results with a distance above this
# value are considered irrelevant, triggering a fallback to generative mode.
RELEVANCE_THRESHOLD = 1.0 

# LOAD MODELS & DATA AT STARTUP
# Models and data are loaded once when the server starts to ensure fast response
# times for API requests, avoiding the overhead of reloading on every call.
print("Loading retriever model (SentenceTransformer)...")
retriever_model = SentenceTransformer('all-MiniLM-L6-v2')
print("Loading vector database (FAISS)...")
jawi_index = faiss.read_index('jawi_index.faiss')
print("Loading knowledge documents...")
with open('documents.json', 'r', encoding='utf-8') as f:
    documents = json.load(f)

# Creates a lookup dictionary for fast, exact-match lookups on core Jawi terms.
# This provides a layer of guaranteed accuracy for the most important queries.
document_lookup = {}
for doc in documents:
    if doc.startswith("Letter name:"):
        try:
            # Extracts a clean name (e.g., 'ca final') from the document string.
            name = doc.split('.')[0].replace("Letter name: ", "").strip().lower()
            document_lookup[name] = doc
        except IndexError:
            continue # Skips any document with an unexpected format.
print(f"✅ Created a lookup dictionary with {len(document_lookup)} core Jawi terms.")

print("✅ Server is ready to accept requests!")
print("-" * 30)

# API ENDPOINTS

@app.route('/chat', methods=['POST'])
def chat():
    """
    Main chat endpoint with a priority-based retrieval logic:
    1. Exact Match: Checks for core Jawi terms first for guaranteed accuracy.
    2. Semantic Search: If no exact match, uses FAISS to find the most relevant context.
    3. Focused Generative: If no relevant context is found, falls back to a guarded generative mode.
    """
    # 1. Receive and Parse Incoming Data
    # Get the JSON data sent from the Flutter application.
    data = request.json
    user_query = data.get('query')
    chat_history = data.get('history', [])
    
    # Get the 'context' sent from the detection screen.
    initial_context = data.get('context')

    # Validate that a query was provided.
    if not user_query: return jsonify({"error": "Query not found"}), 400

    print(f"\n🚀 Received query: '{user_query}' with context: '{initial_context}' and {len(chat_history)} history items.")
    
    # 2. Determine the Search Term
    # This logic makes the chat context-aware. If the app sends an 'initial_context'
    # (like after detecting a letter), we use that for the search. Otherwise, we use the user's typed query.
    search_query = initial_context if initial_context else user_query
    print(f"🔍 Using '{search_query}' as the primary search term.")

    # Use the smarter 'search_query' for the search.
    normalized_query = search_query.lower().strip()
    retrieved_context = None

    # 3. Execute Retrieval Logic (Hybrid RAG)
    # Priority #1: Check for an Exact Match in our lookup dictionary. This is fast and 100% accurate.
    if normalized_query in document_lookup:
        print(f"✅ Exact match found for '{normalized_query}'. Using direct lookup.")
        retrieved_context = document_lookup[normalized_query]
    
    # Priority #2: If no exact match, perform a Semantic Search using FAISS.
    else:
        # Encode the search term into a vector.
        query_embedding = retriever_model.encode([search_query])
        # Search the FAISS index for the most similar document vector.
        distances, indices = jawi_index.search(np.array(query_embedding).astype('float32'), k=1)
        
        # Only use the result if it's below our relevance threshold. This prevents irrelevant results.
        if distances[0][0] <= RELEVANCE_THRESHOLD:
            print(f"✅ Relevant context found via semantic search (distance: {distances[0][0]:.2f}).")
            retrieved_context = documents[indices[0][0]]
        else:
            print(f"⚠️ No relevant context found via semantic search (distance: {distances[0][0]:.2f}).")

    # 4. Prepare Payload for the LLM based on Retrieval Results
    # This logic decides which AI mode to use.
    if retrieved_context:
        # FACTUAL MODE
        # If context was found, use a detailed system prompt to force the AI to be accurate
        # and grounded in the provided facts.
        messages = [
            {
                "role": "system",
                "content": """You are JawiAI, an intelligent and precise AI assistant for the Jawi Script. Follow these rules strictly:
1.  **Grounding Rule:** Your answers MUST be based ONLY on the provided 'Context' and the 'Conversation History'. Do not invent information.
2.  **Formatting Rule:** When giving an example, you MUST use the format: Latin (Jawi).
3.  **Follow-up Rule:** If the user asks for 'another' or 'more', provide another example or detail related to the last topic.
4.  **Repetition Handling Rule:** If you find yourself out of new examples from the 'Context', you MUST offer to switch to a creative mode. For example, say: "I have no more examples for that in my knowledge base. Would you like me to try to **create a new example** for you?"
5.  **Fallback Rule:** If you cannot answer the question based on the provided context or history, state that you do not have that information."""
            }
        ]
        # Add previous conversation messages to maintain context.
        messages.extend(chat_history)
        # Combine the retrieved context with the user's actual question.
        user_content_with_context = f"Context:\n---\n{retrieved_context}\n---\n\nQuestion: {user_query}"
        messages.append({"role": "user", "content": user_content_with_context})
        
        payload = {
            "model": MODEL_NAME,
            "messages": messages,
            "max_tokens": 300,
            "temperature": 0.5 # Lower temperature for more factual, less random responses.
        }
    else:
        # GUARDED GENERATIVE MODE (FALLBACK)
        # If no context was found, use a "guardrail" prompt to ensure the AI stays on topic (Jawi)
        # and doesn't answer unrelated or ambiguous questions.
        print("Switching to FOCUSED generative mode.")
        payload = {
            "model": MODEL_NAME,
            "messages": [
                {
                    "role": "system", 
                    "content": "You are JawiAI, an assistant that ONLY discusses the Jawi script. The user's message seems unclear or off-topic. Politely inform the user that you can only answer questions about the Jawi script and ask them to clarify their question about Jawi."
                },
                *chat_history,
                {"role": "user", "content": user_query}
            ],
            "max_tokens": 1024,
            "temperature": 0.7
        }

    # 5. Call the LLM API and Return the Response
    try:
        # Set the authorization headers and send the request.
        headers = {"Authorization": f"Bearer {QWEN_API_KEY}", "Content-Type": "application/json"}
        response = requests.post(QWEN_API_URL, headers=headers, json=payload, timeout=60)
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx).
        
        # Parse the JSON response and extract the AI's message.
        response_data = response.json()
        ai_response = response_data['choices'][0]['message']['content']
        
        # Return the clean response to the Flutter app.
        return jsonify({"response": ai_response.strip()})
    except Exception as e:
        print(f"Error calling AI model: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/chat-creative', methods=['POST'])
def chat_creative():
    """
    A dedicated endpoint for purely creative tasks, triggered by specific
    keywords in the frontend. This mode does not use RAG and gives the LLM more freedom.
    """
    # Receive and parse the user's query.
    data = request.json
    user_query = data.get('query')
    if not user_query: return jsonify({"error": "Query not found"}), 400

    # A specific prompt designed to encourage creative, rather than factual, output.
    creative_prompt = f"""
    You are a creative Jawi language teacher. Fulfill the user's request creatively. Include both Latin and Jawi script whenever possible.
    Request: "{user_query}"
    Your Creative Answer:
    """
    try:
        # Prepare the payload for the LLM. Note the higher temperature.
        headers = {"Authorization": f"Bearer {QWEN_API_KEY}", "Content-Type": "application/json"}
        payload = {
            "model": MODEL_NAME,
            "messages": [{"role": "user", "content": creative_prompt}],
            "max_tokens": 150,
            "temperature": 0.8 # Higher temperature for more creative, random responses.
        }
        # Call the API and return the response.
        response = requests.post(QWEN_API_URL, headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        response_data = response.json()
        ai_response = response_data['choices'][0]['message']['content']
        return jsonify({"response": ai_response.strip()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
        
# This is the standard entry point for running a Flask application.
if __name__ == '__main__':
    # host='0.0.0.0' makes the server accessible on the local network.
    app.run(host='0.0.0.0', port=5000)