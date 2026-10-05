import 'package:flutter/material.dart';

import '../providers/project_provider.dart';

/// Named ProjectSearchBar to avoid clashing with Material's own SearchBar.
class ProjectSearchBar extends StatefulWidget {
  const ProjectSearchBar({
    super.key,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onSortChanged,
  });

  final String query;
  final SortOption sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SortOption> onSortChanged;

  @override
  State<ProjectSearchBar> createState() => _ProjectSearchBarState();
}

class _ProjectSearchBarState extends State<ProjectSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(covariant ProjectSearchBar old) {
    super.didUpdateWidget(old);
    // The provider can reset the query ("Reset filter"); mirror that in the field.
    if (widget.query != _controller.text.trim()) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: widget.onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama project atau tag',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          widget.onQueryChanged('');
                          setState(() {});
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          PopupMenuButton<SortOption>(
            tooltip: 'Urutkan',
            icon: const Icon(Icons.sort),
            initialValue: widget.sort,
            onSelected: widget.onSortChanged,
            itemBuilder: (_) => [
              for (final s in SortOption.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(s == widget.sort ? Icons.check : null, size: 18),
                      const SizedBox(width: 8),
                      Flexible(child: Text(s.label)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
