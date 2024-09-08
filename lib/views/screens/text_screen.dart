import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindlink_app/share_link/share_dynamic_link.dart';
import 'package:share_plus/share_plus.dart';

class TextPostScreen extends StatefulWidget {
  @override
  _TextPostScreenState createState() => _TextPostScreenState();
}

class _TextPostScreenState extends State<TextPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final CollectionReference _firestore = FirebaseFirestore.instance.collection('text_posts');

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Text Screen',
          style: TextStyle(color: Colors.white, fontSize: screenHeight / 48),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: () => _showCreatePostDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
          )
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Text Post Available"));
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Dismissible(
                onDismissed: (direction) {
                  setState(() {
                    _firestore.doc(post.id).delete();
                  });
                },
                background: Container(color: Colors.red),
                key: Key(post.id),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                      title: Text(post['title']),
                      subtitle: Text(post['description']),
                      trailing: IconButton(
                        icon: Icon(Icons.share, size: screenHeight / 35),
                        onPressed: () async {
                          String postId = post.id;
                          String? dynamicLink = await ShareDynamicLink().createDynamicLink(postId);
                          if (dynamicLink != null) {
                            Share.share(dynamicLink);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        var screenHeight = MediaQuery.of(context).size.height;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Create Post",
                  style: TextStyle(fontSize: screenHeight / 38, fontWeight: FontWeight.w500),
                ),
              ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Enter your title',
                ),
              ),
              SizedBox(height: screenHeight / 30),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Enter your description',
                ),
              ),
              SizedBox(height: screenHeight / 30),
              SizedBox(
                height: screenHeight / 15,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _createPost();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Post',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _createPost() async {
    await FirebaseFirestore.instance.collection('text_posts').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });
    _titleController.clear();
    _descriptionController.clear();
  }
}
