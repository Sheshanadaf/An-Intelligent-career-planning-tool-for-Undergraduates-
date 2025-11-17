import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/user_api.dart';
import '../helpers/utils.dart';

class EditProfileSheet extends StatefulWidget {
  final String userId;
  final String? name;
  final String? bio;
  final String? location;
  final String? imageUrl;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfileSheet({
    super.key,
    required this.userId,
    required this.onProfileUpdated,
    this.name,
    this.bio,
    this.location,
    this.imageUrl,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final picker = ImagePicker();
  File? selectedImage;

  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController locationController;

  @override
  void initState() {
    nameController = TextEditingController(text: widget.name ?? "");
    bioController = TextEditingController(text: widget.bio ?? "");
    locationController = TextEditingController(text: widget.location ?? "");
    super.initState();
  }

  Future pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => selectedImage = File(file.path));
  }

  Future saveProfile() async {
    final api = UserApi();

    final updated = await api.updateProfile(
      userId: widget.userId,
      name: nameController.text,
      bio: bioController.text,
      location: locationController.text,
      imageFile: selectedImage,
    );

    if (updated != null) {
      widget.onProfileUpdated(updated);
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to update profile")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = getFullImageUrl(widget.imageUrl);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : (fullUrl.isNotEmpty
                          ? NetworkImage(fullUrl)
                          : const AssetImage("assets/asd.jpg") as ImageProvider),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: bioController, maxLines: 2, decoration: const InputDecoration(labelText: "Bio", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder())),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Save Changes"),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
