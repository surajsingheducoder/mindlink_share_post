import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:mindlink_app/share_link/share_dynamic_link.dart';
import 'package:share_plus/share_plus.dart';

class ImagePostScreen extends StatefulWidget {
  const ImagePostScreen({super.key});

  @override
  _ImagePostScreenState createState() => _ImagePostScreenState();
}

class _ImagePostScreenState extends State<ImagePostScreen> {
  File? _image;
  final CollectionReference _firestore = FirebaseFirestore.instance.collection('image_posts');
  final TextEditingController _imageTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Image Screen', style: TextStyle(color: Colors.white, fontSize: screenHeight/48),),
        actions: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: () => _pickImage(),
            icon: const Icon(Icons.add, color: Colors.white,),)
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('image_posts')
            .where('type', isEqualTo: 'image')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError){
            return const Text("Something went wrong");
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Image Posts Available"));
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              Timestamp? timestamp = post['timestamp'];

              DateTime? postDate;
              if (timestamp != null) {
                postDate = timestamp.toDate();
              } else {
                postDate = DateTime.now();
                print("Warning: timestamp is null for post $index");
              }

              String formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(postDate);

              return Padding(
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(5)
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Title: ${post['title']}"),
                                Text("Post Date: $formattedDate"),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.all(1),
                            onSelected: (value) {
                           if(value == 'delete'){
                            _firestore.doc(post.id).delete();
                           }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem(
                                  value: 'share',
                                  onTap: () async {
                                    String postId = post.id;
                                    String? dynamicLink = await ShareDynamicLink().createDynamicLink(postId);
                                    Share.share(dynamicLink!);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_outlined, size: screenHeight/35,),
                                    SizedBox(width: screenWidth/30,),
                                      const Text("Share")
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: screenHeight/35,),
                                      SizedBox(width: screenWidth/30,),
                                      const Text("Delete")
                                    ],
                                  ),
                                ),
                              ];
                            },
                          )
                      ],),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5)),
                          child: Image.network(post['mediaUrl'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
      _showUploadDialog();
    }
  }

  void _uploadImage(String title) async {
    try {
      String fileName = _image!.path.split('/').last;
      Reference storageRef = FirebaseStorage.instance.ref().child('image_posts/$fileName');
      await storageRef.putFile(_image!);
      String mediaUrl = await storageRef.getDownloadURL();

      await _firestore.add({
        'mediaUrl': mediaUrl,
        'title': _imageTitleController.text,
        'type': 'image',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _image = null;
        _imageTitleController.clear();
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void _showUploadDialog(){
    showDialog(
      context: context,
      builder: (context) {
     return AlertDialog(
        title: const Text("Add Image title"),
        content: TextField(
          controller: _imageTitleController,
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)
              ),
              labelText: 'Enter your Image title'
          ),
        ),
       actions: [
         TextButton(onPressed: () {
           Navigator.of(context).pop();
         }, child: const Text("Cancel")),
         TextButton(
             onPressed: () {
               if (_imageTitleController.text.isNotEmpty && _image != null) {
                 _uploadImage(_imageTitleController.text);
                 Navigator.of(context).pop();
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Please provide an image and a title'))
                 );
               }
             },
             child: const Text("Upload")
         )
       ],
      );
    },);
  }

  @override
  void dispose() {
    _imageTitleController.dispose();
    super.dispose();
  }
}
