import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:mindlink_app/share_link/share_dynamic_link.dart';
import 'package:mindlink_app/views/screens/video_player_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VideoPostScreen extends StatefulWidget {
  @override
  _VideoPostScreenState createState() => _VideoPostScreenState();
}

class _VideoPostScreenState extends State<VideoPostScreen> {
  File? _video;
  final CollectionReference _firestore = FirebaseFirestore.instance.collection('video_posts');
  final TextEditingController _videoTitleController = TextEditingController();
  VideoPlayerController? _activeVideoController;


  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _video = File(pickedImage.path);
      });
      _showUploadDialog();
    }
  }

  void _uploadImage(String title) async {
    try {
      String fileName = _video!.path.split('/').last;
      Reference storageRef = FirebaseStorage.instance.ref().child('video_posts/$fileName');
      await storageRef.putFile(_video!);
      String mediaUrl = await storageRef.getDownloadURL();

      await _firestore.add({
        'mediaUrl': mediaUrl,
        'title': _videoTitleController.text,
        'type': 'video',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _video = null;
        _videoTitleController.clear();
      });
    } catch (e) {
      print('Error uploading video: $e');
    }
  }

  void _showUploadDialog(){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Video title"),
          content: TextField(
            controller: _videoTitleController,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)
                ),
                labelText: 'Enter your Video title'
            ),
          ),
          actions: [
            TextButton(onPressed: () {
              Navigator.of(context).pop();
            }, child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  if (_videoTitleController.text.isNotEmpty && _video != null) {
                    _uploadImage(_videoTitleController.text);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please provide an video and a title'))
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
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Video Screen', style: TextStyle(color: Colors.white, fontSize: screenHeight/48),),
        actions: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: () => _pickImage(),
            icon: const Icon(Icons.add, color: Colors.white,),)
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError){
            return const ScaffoldMessenger(child: SnackBar(content: Text("Something went wrong")));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Video Posts Available"));
          }
          final posts = snapshot.data!.docs;
          return PageView.builder(
            scrollDirection: Axis.vertical,
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
                            padding: const EdgeInsets.all(1),
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
                          ),
                  
                        ],),
                  
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5)),
                          child: VideoPlayerScreen(url: post['mediaUrl']),
                        ),
                      ),
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

  @override
  void dispose() {
    _videoTitleController.dispose();
    _activeVideoController?.dispose();
    super.dispose();
  }
}
