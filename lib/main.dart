import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() => runApp(NgalongTube());

class NgalongTube extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NgalongTube',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: SearchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ctrl = TextEditingController(text: "playlist ngalong malam");
  List videos = [];
  bool loading = false;

  Future<void> search() async {
    setState(() => loading = true);
    // pake Piped API public (no key)
    final q = Uri.encodeComponent(ctrl.text);
    final url = Uri.parse("https://piped-api.privacy.com.de/search?q=$q");
    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      setState(() {
        videos = data['items']?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🦇 NgalongTube"),
        backgroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: ctrl,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                hintText: "Cari video buat ngalong...",
                filled: true,
                fillColor: Colors.white10,
                suffixIcon: IconButton(icon: Icon(Icons.search), onPressed: search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: loading? Center(child: CircularProgressIndicator()) :
      ListView.builder(
        itemCount: videos.length,
        itemBuilder: (_, i) {
          final v = videos[i];
          return ListTile(
            leading: Image.network(v['thumbnail']?? '', width: 100, fit: BoxFit.cover),
            title: Text(v['title']?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(v['uploaderName']?? ''),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayPage(videoId: v['url']?.split("=")?.last?? v['url']?? ''))),
          );
        },
      ),
    );
  }
}

class PlayPage extends StatefulWidget {
  final String videoId;
  PlayPage({required this.videoId});
  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  VideoPlayerController? _vp;
  ChewieController? _chewie;
  String? streamUrl;

  @override
  void initState() {
    super.initState();
    _loadStream();
  }

  Future<void> _loadStream() async {
    // ambil stream url dari Piped
    final url = Uri.parse("https://piped-api.privacy.com.de/streams/${widget.videoId}");
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    final streams = data['videoStreams'] as List;
    if (streams.isNotEmpty) {
      // ambil 720p
      final s = streams.firstWhere((e) => e['quality'] == '720p', orElse: () => streams.first);
      setState(() => streamUrl = s['url']);
      _vp = VideoPlayerController.networkUrl(Uri.parse(streamUrl!));
      await _vp!.initialize();
      _chewie = ChewieController(videoPlayerController: _vp!, autoPlay: true);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _vp?.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Now Ngalong...")),
      body: _chewie == null? Center(child: CircularProgressIndicator()) : Chewie(controller: _chewie!),
    );
  }
}
