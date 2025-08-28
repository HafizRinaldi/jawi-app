/// A data model class that represents a single saved detection result (a "profile").
/// This class is used to structure the data retrieved from and inserted into the database.
class ProfileModel {
  int? id;
  String? name; // The predicted label of the Jawi letter
  String? image64bit; // The captured image, encoded as a Base64 string
  String? timestamp; // The date and time when the detection was saved
  String? description; // The AI-generated description of the letter

  ProfileModel({
    this.id,
    this.name,
    this.image64bit,
    this.timestamp,
    this.description,
  });

  /// Converts a [ProfileModel] instance into a Map.
  /// The keys must correspond to the names of the columns in the database.
  /// This is used for inserting data into the database.
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "name": name,
      "image64bit": image64bit,
      "timestamp": timestamp,
      "description": description,
    };

    // The 'id' is only included in the map if it's not null, as the database
    // will auto-generate it upon insertion.
    if (id != null) {
      map["id"] = id;
    }

    return map;
  }

  /// A factory constructor to create a [ProfileModel] instance from a Map.
  /// This is used for converting data retrieved from the database back into
  /// a structured object.
  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
    id: map["id"],
    name: map["name"],
    image64bit: map["image64bit"],
    timestamp: map["timestamp"],
    description: map["description"],
  );
}
