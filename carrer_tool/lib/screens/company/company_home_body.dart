// lib/screens/company/company_home_body.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../company/services/company_api.dart';
import 'view_rank_screen.dart';

const kPrimaryColor = Color(0xFF3B82F6);
const kAppBarColor = Color(0xFF1976D2);
const kBackgroundColor = Color(0xFFFCFCFD);

class CompanyHomeBody extends StatefulWidget {
  final String companyName;
  final String companyReg;
  final String companyDis;
  final String companyLogo;
  final String companyId;
  final VoidCallback? refreshParent;

  const CompanyHomeBody({
    super.key,
    required this.companyName,
    required this.companyReg,
    required this.companyDis,
    required this.companyLogo,
    required this.companyId,
    this.refreshParent,
  });

  @override
  State<CompanyHomeBody> createState() => _CompanyHomeBodyState();
}

class _CompanyHomeBodyState extends State<CompanyHomeBody>
    with WidgetsBindingObserver {
  final CompanyApi _companyApi = CompanyApi();

  List<dynamic> _jobPosts = [];
  bool _isLoading = true;

  // Profile (local mutable copy)
  late String _companyName;
  late String _companyReg;
  late String _companyDis;
  late String _companyLogo;

  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _companyName = widget.companyName;
    _companyReg = widget.companyReg;
    _companyDis = widget.companyDis;
    _companyLogo = widget.companyLogo;

    _loadJobPosts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!) > const Duration(seconds: 3)) {
        _lastRefreshTime = now;
        _loadJobPosts();
      }
    }
  }

  Future<void> _loadJobPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final posts = await _companyApi.fetchCompanyPosts();
      if (!mounted) return;
      setState(() {
        _jobPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading job posts: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditProfileSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EditProfileSheet(
          initialName: _companyName,
          initialReg: _companyReg,
          initialDis: _companyDis,
          initialLogo: _companyLogo,
          companyApi: _companyApi,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _companyName = result['companyName'] ?? _companyName;
        _companyReg = result['companyReg'] ?? _companyReg;
        _companyDis = result['companyDis'] ?? _companyDis;
        _companyLogo = result['companyLogo'] ?? _companyLogo;
      });

      widget.refreshParent?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );

      await _loadJobPosts();
    }
  }

  ImageProvider? _imageProviderFromPath(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('http')) {
      // Cache-busting
      return NetworkImage('$path?v=${DateTime.now().millisecondsSinceEpoch}');
    }
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context) {
    final header = CompanyProfileHeader(
      companyName: _companyName,
      companyReg: _companyReg,
      companyDis: _companyDis,
      imageProvider: _imageProviderFromPath(_companyLogo),
      onEditPressed: _openEditProfileSheet,
    );

    return RefreshIndicator(
      onRefresh: _loadJobPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            header,
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Job Posts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 20,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            else if (_jobPosts.isEmpty)
              Center(
                child: Text(
                  'No job posts available.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              )
            else
              Column(
                children: _jobPosts
                    .map((p) => JobCard(
                          post: Map<String, dynamic>.from(p),
                          onViewRank: (post) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewRankScreen(
                                  jobRole: post['jobRole'] ?? '',
                                  jobPostId: post['_id'] ?? '',
                                  weights: post['weights'] != null
                                      ? Map<String, dynamic>.from(post['weights'])
                                      : {
                                          "university": 0,
                                          "gpa": 0,
                                          "certifications": 0,
                                          "projects": 0
                                        },
                                  companyName: _companyName,
                                ),
                              ),
                            );
                            await _loadJobPosts();
                          },
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- CompanyProfileHeader ----------------------
class CompanyProfileHeader extends StatefulWidget {
  final String companyName;
  final String companyReg;
  final String companyDis;
  final ImageProvider? imageProvider;
  final VoidCallback onEditPressed;

  const CompanyProfileHeader({
    super.key,
    required this.companyName,
    required this.companyReg,
    required this.companyDis,
    required this.imageProvider,
    required this.onEditPressed,
  });

  @override
  State<CompanyProfileHeader> createState() => _CompanyProfileHeaderState();
}

class _CompanyProfileHeaderState extends State<CompanyProfileHeader>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
Widget build(BuildContext context) {
  final img = widget.imageProvider;

  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => setState(() => _expanded = !_expanded),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 500), // slower animation
      curve: Curves.easeInOutCubic, // smooth cubic curve
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kAppBarColor], // remove const
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedCrossFade(
        firstChild: _buildCollapsed(img),
        secondChild: _buildExpanded(img),
        crossFadeState:
            _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 500),
        firstCurve: Curves.easeInOut,
        secondCurve: Curves.easeInOut,
        sizeCurve: Curves.easeInOut,
      ),
    ),
  );
}


  Widget _buildExpanded(ImageProvider? img) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.black12,
          backgroundImage: img,
          child: img == null
              ? const Icon(Icons.business, size: 48, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 12),
        Text(widget.companyName,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text("Reg No: ${widget.companyReg}",
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Text(widget.companyDis,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.justify),
        const SizedBox(height: 8),
        IconButton(
          onPressed: widget.onEditPressed,
          icon: const Icon(Icons.edit, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCollapsed(ImageProvider? img) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.black12,
          backgroundImage: img,
          child: img == null
              ? const Icon(Icons.business, size: 36, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.companyName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text("Reg No: ${widget.companyReg}",
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(widget.companyDis,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        IconButton(
            onPressed: widget.onEditPressed,
            icon: const Icon(Icons.edit, color: Colors.white)),
      ],
    );
  }
}

// ---------------------- JobCard ----------------------
class JobCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Future<void> Function(Map<String, dynamic> post) onViewRank;

  const JobCard({super.key, required this.post, required this.onViewRank});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isExpanded = false;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final jobRole = post['jobRole'] ?? 'Unknown Role';
    final weights = post['weights'] != null
        ? Map<String, dynamic>.from(post['weights'])
        : {"university": 0, "gpa": 0, "certifications": 0, "projects": 0};

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _isHovered ? Colors.blue.shade50 : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                blurRadius: _isHovered ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300.withOpacity(0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(jobRole,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => widget.onViewRank(post),
                      icon: const Icon(Icons.bar_chart, size: 16, color: Colors.white), // white icon
                      label:
                          const Text(
                            'Rank',
                            style: TextStyle(fontSize: 12, color: Colors.white), // white text
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post['description'] != null) ...[
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post['description'],
                            textAlign: TextAlign.justify,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (post['skills'] != null) ...[
                          const Text(
                            "Required Skills",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post['skills'],
                            textAlign: TextAlign.justify,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (post['certifications'] != null) ...[
                          const Text(
                            "Certifications",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post['certifications'],
                            textAlign: TextAlign.justify,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (post['details'] != null) ...[
                          const Text(
                            "Other Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post['details'],
                            textAlign: TextAlign.justify,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                        ],

                        WeightsBar(weights: weights),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------- WeightsBar ----------------------
class WeightsBar extends StatelessWidget {
  final Map<String, dynamic> weights;
  const WeightsBar({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    final labels = ['Uni.', 'GPA', 'Cer.', 'Pro.'];
    final keys = ['university', 'gpa', 'certifications', 'projects'];
    final colors = [
      kPrimaryColor,
      Colors.blue.shade400,
      Colors.cyan.shade300,
      Colors.teal.shade400
    ];

    final filtered = <Map<String, dynamic>>[];
    for (int i = 0; i < keys.length; i++) {
      final value = (weights[keys[i]] ?? 0) as num;
      if (value > 0) filtered.add(
          {'label': labels[i], 'value': value, 'color': colors[i]});
    }

    if (filtered.isEmpty) return const SizedBox.shrink();

    final total = filtered.fold<num>(0, (sum, e) => sum + (e['value'] as num));

    return Container(
      height: 26,
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: filtered.map((e) {
          final flexValue = ((e['value'] as num) * 100 ~/ total).clamp(1, 100);
          return Flexible(
            flex: flexValue,
            child: Container(
              decoration: BoxDecoration(
                color: e['color'] as Color,
                borderRadius: BorderRadius.horizontal(
                  left: e == filtered.first ? const Radius.circular(12) : Radius.zero,
                  right: e == filtered.last ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              alignment: Alignment.center,
              child: Text('${e['label']} ${e['value']}%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------- EditProfileSheet ----------------------
class EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialReg;
  final String initialDis;
  final String initialLogo;
  final CompanyApi companyApi;

  const EditProfileSheet({
    super.key,
    required this.initialName,
    required this.initialReg,
    required this.initialDis,
    required this.initialLogo,
    required this.companyApi,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _regCtl;
  late final TextEditingController _disCtl;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.initialName);
    _regCtl = TextEditingController(text: widget.initialReg);
    _disCtl = TextEditingController(text: widget.initialDis);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _regCtl.dispose();
    _disCtl.dispose();
    super.dispose();
  }

  ImageProvider? _currentImageProvider() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (widget.initialLogo.isNotEmpty) {
      if (widget.initialLogo.startsWith('http')) {
        return NetworkImage(
            '${widget.initialLogo}?v=${DateTime.now().millisecondsSinceEpoch}');
      }
      final f = File(widget.initialLogo);
      return f.existsSync() ? FileImage(f) : null;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final updated = await widget.companyApi.updateProfileWithImage(
        name: _nameCtl.text.trim(),
        reg: _regCtl.text.trim(),
        dis: _disCtl.text.trim(),
        logoFile: _selectedImage,
      );

      final returnMap = <String, dynamic>{};
      if (updated != null) {
        returnMap['companyName'] =
            updated['companyName'] ?? _nameCtl.text.trim();
        returnMap['companyReg'] =
            updated['companyReg'] ?? _regCtl.text.trim();
        returnMap['companyDis'] =
            updated['companyDis'] ?? _disCtl.text.trim();

        if (_selectedImage != null) {
          returnMap['companyLogo'] = _selectedImage!.path;
        } else if (updated['companyLogo'] != null) {
          returnMap['companyLogo'] =
              '${updated['companyLogo']}?v=${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      if (mounted) Navigator.pop(context, updated != null ? returnMap : null);
    } catch (e) {
      debugPrint('Update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Update failed')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _currentImageProvider();
    return Material(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black12,
                  backgroundImage: img,
                  child: img == null
                      ? const Icon(Icons.business, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _nameCtl,
                  decoration:
                      const InputDecoration(labelText: 'Company Name')),
              const SizedBox(height: 8),
              TextField(
                  controller: _regCtl, decoration: const InputDecoration(labelText: 'Reg No')),
              const SizedBox(height: 8),
              TextField(
                  controller: _disCtl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'Save',
                            style: TextStyle(color: Colors.white), // <-- white text
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
