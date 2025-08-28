# ingest.py
# This script performs a one-time data ingestion process.
# It reads the structured knowledge from `jawi_knowledge.json`, formats it into plain text,
# creates vector embeddings using a SentenceTransformer model, and saves them into a
# searchable FAISS index (`jawi_index.faiss`). It also saves the formatted text
# documents (`documents.json`) for later retrieval.

import json
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np

print("Starting the data ingestion process...")

# Step 1: Read the source knowledge base from the JSON file.
# This file contains the structured, human-readable information about Jawi.
with open('jawi_knowledge.json', 'r', encoding='utf-8') as f:
    knowledge_base = json.load(f)

# This list will hold the formatted plain text strings for processing.
documents = []

# Step 2: Process and format each item from the knowledge base into a single string.
# This flattened format is required for the embedding model and for providing context to the LLM.
for item in knowledge_base:
    if item.get('type') == 'general_topic':
        # Format for general informational topics.
        text = f"Topic: {item['topic']}. Explanation: {item['content']}"
        documents.append(text)
    elif item.get('type') == 'letter':
        # Format for specific Jawi letter details.
        text = (f"Letter name: {item['name']}. "
                f"Jawi character form: {item.get('character', '')}. "
                f"Info: {item['info']} "
                f"Example word in Latin is '{item.get('latin_example', '')}' "
                f"and in Jawi is '{item.get('jawi_example', '')}'.")
        documents.append(text)

print(f"A total of {len(documents)} documents will be processed.")

# Step 3: Load the SentenceTransformer model.
# 'all-MiniLM-L6-v2' is a lightweight and efficient model for creating high-quality
# vector embeddings from text.
print("Loading SentenceTransformer model 'all-MiniLM-L6-v2'...")
model = SentenceTransformer('all-MiniLM-L6-v2')

# Step 4: Create vector embeddings for all formatted documents.
# This converts each text string into a numerical vector that represents its semantic meaning.
print("Creating embeddings for all documents...")
embeddings = model.encode(documents, convert_to_tensor=False)

# Step 5: Build and save the FAISS vector index.
# FAISS (Facebook AI Similarity Search) is a library for efficient similarity search.
# We use IndexFlatL2, a standard index for dense vector search.
print("Building and saving the index to 'jawi_index.faiss'...")
dimension = embeddings.shape[1]  # Get the dimension of the embeddings (e.g., 384 for MiniLM).
index = faiss.IndexFlatL2(dimension)
index.add(np.array(embeddings).astype('float32')) # Add the vectors to the index.
faiss.write_index(index, 'jawi_index.faiss') # Save the index to disk.

# Step 6: Save the formatted text documents.
# This file is used by the main app to retrieve the original text corresponding
# to an index found by the FAISS search.
print("Saving the text documents to 'documents.json'...")
with open('documents.json', 'w', encoding='utf-8') as f:
    json.dump(documents, f, ensure_ascii=False, indent=4)

print("✅ Ingestion process complete! The vector database and documents have been updated.")