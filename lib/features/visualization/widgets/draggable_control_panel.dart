import 'package:flutter/material.dart';

/// Перетаскиваемая панель управления с возможностью изменения размера
class DraggableControlPanel extends StatefulWidget {
  final Widget child;
  final String title;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final Offset initialPosition;
  
  const DraggableControlPanel({
    super.key,
    required this.child,
    required this.title,
    this.initialWidth = 350,
    this.initialHeight = 400,
    this.minWidth = 250,
    this.minHeight = 200,
    this.maxWidth = 500,
    this.maxHeight = 800,
    this.initialPosition = const Offset(20, 20),
  });

  @override
  State<DraggableControlPanel> createState() => _DraggableControlPanelState();
}

class _DraggableControlPanelState extends State<DraggableControlPanel> {
  late Offset _position;
  late double _width;
  late double _height;
  bool _isCollapsed = false;
  
  // Для изменения размера
  bool _isResizing = false;
  Offset? _resizeStartPosition;
  double? _resizeStartWidth;
  double? _resizeStartHeight;
  
  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _width = widget.initialWidth;
    _height = widget.initialHeight;
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _width,
        height: _isCollapsed ? 52 : _height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Заголовок панели
            GestureDetector(
              onPanStart: (details) {
                // Начало перетаскивания
              },
              onPanUpdate: (details) {
                setState(() {
                  final screenSize = MediaQuery.of(context).size;
                  _position = Offset(
                    (_position.dx + details.delta.dx).clamp(0, screenSize.width - _width),
                    (_position.dy + details.delta.dy).clamp(0, screenSize.height - 100),
                  );
                });
              },
              onPanEnd: (details) {
                // Конец перетаскивания
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Кнопка сворачивания
                    IconButton(
                      icon: Icon(
                        _isCollapsed ? Icons.expand_more : Icons.expand_less,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            // Содержимое панели
            if (!_isCollapsed) ...[
              Expanded(
                child: Stack(
                  children: [
                    // Прокручиваемое содержимое
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: widget.child,
                      ),
                    ),
                    
                    // Уголок для изменения размера
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _isResizing = true;
                            _resizeStartPosition = details.globalPosition;
                            _resizeStartWidth = _width;
                            _resizeStartHeight = _height;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isResizing && _resizeStartPosition != null) {
                            final delta = details.globalPosition - _resizeStartPosition!;
                            setState(() {
                              _width = (_resizeStartWidth! + delta.dx)
                                  .clamp(widget.minWidth, widget.maxWidth);
                              _height = (_resizeStartHeight! + delta.dy)
                                  .clamp(widget.minHeight, widget.maxHeight);
                            });
                          }
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _isResizing = false;
                            _resizeStartPosition = null;
                            _resizeStartWidth = null;
                            _resizeStartHeight = null;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Icon(
                            Icons.zoom_out_map,
                            size: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}