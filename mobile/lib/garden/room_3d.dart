import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../core/progress_store.dart';
import 'garden_catalog.dart';

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;
  Vec3 operator +(Vec3 b) => Vec3(x + b.x, y + b.y, z + b.z);
  Vec3 operator -(Vec3 b) => Vec3(x - b.x, y - b.y, z - b.z);
  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);
  double dot(Vec3 b) => x * b.x + y * b.y + z * b.z;
}

/// Perspective camera over real world-space geometry, not a rotated bitmap.
class RoomCamera {
  const RoomCamera({this.yaw = .35, this.pitch = .56, this.distance = 15});
  final double yaw, pitch, distance;
  Vec3 get right => Vec3(math.cos(yaw), 0, -math.sin(yaw));
  Vec3 get up => Vec3(
    -math.sin(yaw) * math.sin(pitch),
    math.cos(pitch),
    -math.cos(yaw) * math.sin(pitch),
  );
  Vec3 get forward => Vec3(
    -math.sin(yaw) * math.cos(pitch),
    -math.sin(pitch),
    -math.cos(yaw) * math.cos(pitch),
  );
  Vec3 get eye => const Vec3(0, 1, 0) - forward * distance;
  double depth(Vec3 point) => (point - eye).dot(forward);
  Offset project(Vec3 point, Size size) {
    final v = point - eye;
    final f = size.shortestSide * 1.1;
    final d = depth(point).clamp(.1, 1000);
    return Offset(
      size.width / 2 + v.dot(right) * f / d,
      size.height * .51 - v.dot(up) * f / d,
    );
  }

  Vec3? intersect(Offset point, Size size, {bool wall = false}) {
    final f = size.shortestSide * 1.1;
    final ray =
        forward +
        right * ((point.dx - size.width / 2) / f) -
        up * ((point.dy - size.height * .51) / f);
    final divisor = wall ? ray.z : ray.y;
    if (divisor.abs() < .001) return null;
    final t = wall ? (-3.85 - eye.z) / divisor : -eye.y / divisor;
    return t > 0 ? eye + ray * t : null;
  }
}

class RoomFace {
  const RoomFace(this.points, this.color, {this.slot});
  final List<Vec3> points;
  final Color color;
  final int? slot;
  Vec3 get centre => points.reduce((a, b) => a + b) * (1 / points.length);
  Path path(RoomCamera camera, Size size) {
    final projected = points.map((v) => camera.project(v, size)).toList();
    return Path()..addPolygon(projected, true);
  }
}

class RoomMesh {
  final faces = <RoomFace>[];
  int? slot;
  Vec3 origin = const Vec3(0, 0, 0);
  void face(List<Vec3> points, Color color) => faces.add(
    RoomFace(points.map((p) => p + origin).toList(), color, slot: slot),
  );
  Color shade(Color c, double k) => Color.fromARGB(
    255,
    (c.r * 255 * k).round().clamp(0, 255),
    (c.g * 255 * k).round().clamp(0, 255),
    (c.b * 255 * k).round().clamp(0, 255),
  );
  void box(
    double x,
    double y,
    double z,
    double w,
    double h,
    double d,
    Color c,
  ) {
    final a = Vec3(x - w / 2, y, z - d / 2),
        b = Vec3(x + w / 2, y, z - d / 2),
        cc = Vec3(x + w / 2, y, z + d / 2),
        dd = Vec3(x - w / 2, y, z + d / 2);
    final dy = Vec3(0, h, 0);
    face([a, b, cc, dd], shade(c, .65));
    face([a, a + dy, b + dy, b], shade(c, .78));
    face([b, b + dy, cc + dy, cc], shade(c, .88));
    face([cc, cc + dy, dd + dy, dd], c);
    face([dd, dd + dy, a + dy, a], shade(c, .92));
    face([a + dy, dd + dy, cc + dy, b + dy], shade(c, 1.08));
  }

  void cylinder(
    double x,
    double y,
    double z,
    double radius,
    double height,
    Color c, {
    double? topRadius,
    int sides = 12,
  }) {
    final top = <Vec3>[];
    for (var i = 0; i < sides; i++) {
      final a = i * math.pi * 2 / sides, b = (i + 1) * math.pi * 2 / sides;
      final r = topRadius ?? radius;
      final p = Vec3(x + math.cos(a) * radius, y, z + math.sin(a) * radius);
      final q = Vec3(x + math.cos(b) * radius, y, z + math.sin(b) * radius);
      final pt = Vec3(x + math.cos(a) * r, y + height, z + math.sin(a) * r);
      final qt = Vec3(x + math.cos(b) * r, y + height, z + math.sin(b) * r);
      face([p, pt, qt, q], shade(c, .86 + .14 * math.cos(a)));
      top.add(pt);
    }
    face(top, shade(c, 1.08));
  }
}

const _cream = Color(0xFFE8DCC3),
    _blue = Color(0xFF215A82),
    _gold = Color(0xFFC7A35A),
    _wood = Color(0xFFAD7950);

GardenPosition roomPosition(PlayerProgress p, int slot) =>
    p.homePositions[slot] ??
    GardenPosition(.23 + (slot % 4) * .18, .64 + (slot ~/ 4) * .13);

RoomMesh furnitureMesh(PlayerProgress progress) {
  final m = RoomMesh();
  for (final entry in progress.homePlacements.entries) {
    final item = gardenItems.firstWhere((i) => i.id == entry.value);
    final pos = roomPosition(progress, entry.key);
    m.slot = entry.key;
    m.origin = Vec3(
      (pos.x - .5) * 12,
      0,
      item.wall ? -3.85 : (pos.y - .775) * 18,
    );
    final premium = item.premium;
    final start = m.faces.length;
    final model = item.model ?? item.id;
    switch (model) {
      case 'sofa':
      case 'cream_sofa':
      case 'chair':
        final w = model == 'chair' ? 1.25 : 2.7;
        final c = premium ? _blue : _cream;
        for (final x in [-w / 2 + .12, w / 2 - .12]) {
          for (final z in [-.48, .48]) {
            m.box(x, 0, z, .10, .35, .10, _wood);
          }
        }
        m.box(0, .28, 0, w, .32, 1.2, _wood);
        m.box(0, .6, -.48, w, 1, .24, c);
        m.box(0, .6, .05, w - .28, .26, .94, c);
        for (final x in [-w / 2 + .08, w / 2 - .08]) {
          m.box(x, .55, .08, .22, .65, 1.28, c);
        }
        if (w > 2) {
          m.box(
            0,
            .86,
            -.12,
            .025,
            .55,
            .5,
            premium ? _gold : const Color(0xFFC9BBA3),
          );
        }
        if (premium) {
          for (final x in [-.78, .78]) {
            m.box(x, .86, -.2, .45, .5, .25, _gold);
          }
        }
      case 'rug':
      case 'royal_rug':
        m.box(0, .015, 0, 3.8, .025, 2.5, premium ? _gold : _blue);
        m.box(0, .041, 0, 3.5, .01, 2.25, _blue);
        if (premium) {
          m.box(0, .054, 0, 1.3, .01, .95, _gold);
          m.box(0, .065, 0, 1, .01, .65, _blue);
          for (final x in [-1.5, -1.0, -.5, 0.0, .5, 1.0, 1.5]) {
            for (final z in [-.94, .94]) {
              m.box(x, .055, z, .12, .01, .12, _gold);
            }
          }
        }
      case 'table':
        for (final x in [-.65, .65]) {
          for (final z in [-.38, .38]) {
            m.box(x, 0, z, .10, .65, .10, _wood);
          }
        }
        m.box(0, .65, 0, 1.6, .12, 1.05, _wood);
      case 'lamp':
      case 'crystal_lamp':
      case 'lantern':
        m.cylinder(0, 0, 0, .3, .08, _gold);
        m.cylinder(0, .08, 0, .045, 1.8, _gold, sides: 8);
        m.cylinder(0, 1.7, 0, .45, .55, _cream, topRadius: .25);
        if (premium) {
          for (var n = 0; n < 10; n++) {
            final a = n * math.pi / 5;
            m.cylinder(
              math.cos(a) * .38,
              1.48,
              math.sin(a) * .38,
              .035,
              .24,
              const Color(0xFFACDAE6),
              sides: 5,
            );
          }
        }
      case 'linen':
      case 'curtains':
        m.box(0, 3.3, .08, 3.3, .06, .08, _gold);
        for (final side in [-1, 1]) {
          for (var i = 0; i < 7; i++) {
            m.cylinder(
              side * (.9 + i * .09),
              .9,
              .13,
              .065,
              2.4,
              premium ? const Color(0xFF256A70) : _cream,
              sides: 6,
            );
          }
          m.box(side * 1.17, 1.6, .2, .65, .07, .06, _gold);
        }
      case 'painting':
      case 'gallery':
        final y = 1.5 + (pos.y - .22) * 4;
        final count = premium ? 3 : 1;
        for (var n = 0; n < count; n++) {
          final x = (n - (count - 1) / 2) * .78;
          m.box(x, y, .06, .7, .95, .09, _gold);
          m.box(x, y + .06, .12, .59, .82, .035, const Color(0xFFB4D6E0));
          m.face([
            Vec3(x - .27, y + .12, .145),
            Vec3(x + .27, y + .12, .145),
            Vec3(x + .08, y + .65, .145),
          ], _blue);
        }
      case 'bed':
      case 'royal_bed':
        m.box(0, .15, 0, 2.5, .4, 3.1, _wood);
        m.box(0, .55, 0, 2.45, .3, 3, _cream);
        m.box(
          0,
          .86,
          .45,
          2.46,
          .07,
          2,
          premium ? _blue : const Color(0xFF96B7AF),
        );
        m.box(0, .25, -1.5, 2.6, 1.4, .18, premium ? _blue : _wood);
        for (final x in [-.63, .63]) {
          m.box(x, .85, -.95, .95, .2, .55, _cream);
        }
        if (premium) {
          m.box(0, .94, .95, 2.46, .03, .18, _gold);
        }
      default:
        final c = model == 'roses'
            ? const Color(0xFFBF7956)
            : const Color(0xFF428C98);
        m.cylinder(0, 0, 0, .27, .55, c, topRadius: .38);
        if (model != 'jar') {
          for (var n = 0; n < 7; n++) {
            final a = n * 2.4, x = math.cos(a) * .28, z = math.sin(a) * .28;
            m.cylinder(x, .5, z, .018, .35, const Color(0xFF587D43), sides: 5);
            m.cylinder(
              x,
              .8,
              z,
              .15,
              .12,
              model == 'lavender'
                  ? const Color(0xFF9773B9)
                  : model == 'roses'
                  ? const Color(0xFFE4A4B2)
                  : _cream,
              sides: 7,
            );
          }
        }
    }
    if (item.tint != null) {
      for (var n = start; n < m.faces.length; n++) {
        final f = m.faces[n];
        m.faces[n] = RoomFace(
          f.points,
          Color.lerp(f.color, Color(item.tint!), .48)!,
          slot: f.slot,
        );
      }
    }
  }
  return m;
}

// Own gestures starting in the viewport so the surrounding catalogue cannot
// steal vertical drags. Pointer streams remain with Flutter's scale recognizer.
class _RoomScaleRecognizer extends ScaleGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class Room3DScene extends StatefulWidget {
  const Room3DScene({
    super.key,
    required this.progress,
    required this.editing,
    required this.selected,
    required this.onSelect,
    required this.onMove,
    required this.onSave,
  });
  final PlayerProgress progress;
  final bool editing;
  final int selected;
  final ValueChanged<int> onSelect;
  final void Function(int, double, double) onMove;
  final VoidCallback onSave;
  @override
  State<Room3DScene> createState() => Room3DSceneState();
}

class Room3DSceneState extends State<Room3DScene> {
  RoomCamera camera = const RoomCamera();
  bool orbit = true;
  Offset? down;
  int? moving;
  double startDistance = 15;
  int? hit(Offset point, Size size) {
    final rugs = widget.progress.homePlacements.entries
        .where(
          (e) =>
              gardenItems.firstWhere((i) => i.id == e.value).category == 'Rugs',
        )
        .map((e) => e.key)
        .toSet();
    final faces = furnitureMesh(widget.progress).faces
      ..sort((a, b) {
        final ar = rugs.contains(a.slot);
        final br = rugs.contains(b.slot);
        if (ar != br) return ar ? 1 : -1;
        return camera.depth(a.centre).compareTo(camera.depth(b.centre));
      });
    for (final f in faces) {
      if (f.path(camera, size).contains(point)) return f.slot;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          return Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (event) {
                    down ??= event.localPosition;
                    if (widget.editing) {
                      final slot = hit(event.localPosition, size);
                      if (slot != null) widget.onSelect(slot);
                    }
                  },
                  onPointerUp: (_) => down = null,
                  onPointerCancel: (_) => down = null,
                  child: RawGestureDetector(
                    key: const ValueKey('room-3d-viewport'),
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      _RoomScaleRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            _RoomScaleRecognizer
                          >(() => _RoomScaleRecognizer(), (r) {
                            r
                              ..onStart = (d) {
                                startDistance = camera.distance;
                                moving = widget.editing && !orbit
                                    ? hit(down ?? d.localFocalPoint, size)
                                    : null;
                                if (moving != null) widget.onSelect(moving!);
                              }
                              ..onUpdate = (d) {
                                final delta = d.focalPointDelta;
                                if (d.pointerCount > 1) {
                                  setState(
                                    () => camera = RoomCamera(
                                      yaw: camera.yaw,
                                      pitch: camera.pitch,
                                      distance: (startDistance / d.scale).clamp(
                                        10,
                                        23,
                                      ),
                                    ),
                                  );
                                } else if (moving != null &&
                                    widget.editing &&
                                    !orbit) {
                                  final id =
                                      widget.progress.homePlacements[moving];
                                  final item = gardenItems.firstWhere(
                                    (i) => i.id == id,
                                  );
                                  final point = camera.intersect(
                                    d.localFocalPoint,
                                    size,
                                    wall: item.wall,
                                  );
                                  if (point != null) {
                                    widget.onMove(
                                      moving!,
                                      point.x / 12 + .5,
                                      item.wall
                                          ? (point.y - 1.5) / 4 + .22
                                          : point.z / 18 + .775,
                                    );
                                  }
                                } else if (orbit || !widget.editing) {
                                  setState(
                                    () => camera = RoomCamera(
                                      yaw:
                                          (camera.yaw - delta.dx * .009) %
                                          (math.pi * 2),
                                      pitch: (camera.pitch + delta.dy * .006)
                                          .clamp(.2, 1.15),
                                      distance: camera.distance,
                                    ),
                                  );
                                }
                              }
                              ..onEnd = (_) {
                                if (moving != null) widget.onSave();
                                moving = null;
                                down = null;
                              };
                          }),
                    },
                    child: CustomPaint(
                      painter: Room3DPainter(
                        widget.progress,
                        camera,
                        widget.editing ? widget.selected : null,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  label: Text(
                    widget.editing && !orbit
                        ? 'Drag furniture'
                        : '3D · Drag to rotate',
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: 'Reset camera',
                  onPressed: () => setState(() => camera = const RoomCamera()),
                  icon: const Icon(Icons.center_focus_strong),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (widget.editing)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Rotate view'),
                        icon: Icon(Icons.threed_rotation),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Move items'),
                        icon: Icon(Icons.open_with),
                      ),
                    ],
                    selected: {orbit},
                    onSelectionChanged: (s) => setState(() => orbit = s.single),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class Room3DPainter extends CustomPainter {
  Room3DPainter(this.progress, this.camera, this.selected);
  final PlayerProgress progress;
  final RoomCamera camera;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    canvas.drawRect(
      Offset.zero & size,
      paint
        ..shader = const LinearGradient(
          colors: [Color(0xFF19354B), Color(0xFF071A29)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    paint.shader = null;
    void draw(List<RoomFace> faces, {bool highlight = false}) {
      faces.sort(
        (a, b) => camera.depth(b.centre).compareTo(camera.depth(a.centre)),
      );
      for (final f in faces) {
        if (f.points.any((p) => camera.depth(p) <= .1)) continue;
        final path = f.path(camera, size);
        canvas.drawPath(
          path,
          paint
            ..style = PaintingStyle.fill
            ..color = f.color,
        );
        if (highlight && selected == f.slot) {
          canvas.drawPath(
            path,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = .65
              ..color = const Color(0xFFFFD979),
          );
        }
      }
      paint.style = PaintingStyle.fill;
    }

    final floor = RoomMesh()..box(0, -.18, 0, 10, .18, 8, _wood);
    draw(floor.faces);
    for (double x = -5; x <= 5; x += .5) {
      canvas.drawLine(
        camera.project(Vec3(x, .003, -4), size),
        camera.project(Vec3(x, .003, 4), size),
        paint
          ..color = const Color(0x55805C3A)
          ..strokeWidth = .6,
      );
    }
    for (double z = -4; z <= 4; z += 1) {
      canvas.drawLine(
        camera.project(Vec3(-5, .003, z), size),
        camera.project(Vec3(5, .003, z), size),
        paint..color = const Color(0x44805C3A),
      );
    }
    final walls = RoomMesh();
    // Cutaway walls on the far side leave the room visible throughout 360° orbit.
    final back = camera.eye.z >= 0 ? -4.0 : 4.0;
    walls.box(0, 0, back, 10, 3.8, .12, _cream);
    walls.box(0, 0, back * .99, 10, .12, .08, const Color(0xFFFFF2D7));
    if (camera.eye.x.abs() > 1) {
      walls.box(
        camera.eye.x >= 0 ? -5 : 5,
        0,
        0,
        .12,
        3.8,
        8,
        const Color(0xFFD4D9D0),
      );
    }
    if (back < 0) {
      walls.box(0, 1.1, -3.91, 3, 2.05, .05, const Color(0xFF9CCBD8));
      for (final x in [-1.5, 0.0, 1.5]) {
        walls.box(x, 1.08, -3.84, .07, 2.1, .08, const Color(0xFFFFF4DD));
      }
      for (final y in [1.08, 2.1, 3.15]) {
        walls.box(0, y, -3.84, 3.07, .06, .08, const Color(0xFFFFF4DD));
      }
    }
    draw(walls.faces);
    final rugSlots = progress.homePlacements.entries
        .where(
          (e) =>
              gardenItems.firstWhere((i) => i.id == e.value).category == 'Rugs',
        )
        .map((e) => e.key)
        .toSet();
    final furnishings = furnitureMesh(progress).faces;
    draw(
      furnishings.where((f) => rugSlots.contains(f.slot)).toList(),
      highlight: true,
    );
    draw(
      furnishings.where((f) => !rugSlots.contains(f.slot)).toList(),
      highlight: true,
    );
  }

  @override
  bool shouldRepaint(covariant Room3DPainter oldDelegate) => true;
}

class RoomItemPainter extends CustomPainter {
  const RoomItemPainter(this.item);
  final GardenItem item;
  @override
  void paint(Canvas canvas, Size size) {
    final p = PlayerProgress(
      owned: {item.id},
      homePlacements: {0: item.id},
      homePositions: {0: const GardenPosition(.5, .775)},
    );
    final camera = RoomCamera(
      yaw: item.wall ? .15 : .5,
      pitch: .35,
      distance: item.id.contains('bed') || item.category == 'Rugs' ? 6 : 5,
    );
    final raw = furnitureMesh(p).faces;
    final faces = item.wall
        ? raw
              .map(
                (f) => RoomFace(
                  f.points.map((v) => v + const Vec3(0, 0, 3.85)).toList(),
                  f.color,
                ),
              )
              .toList()
        : raw;
    faces.sort(
      (a, b) => camera.depth(b.centre).compareTo(camera.depth(a.centre)),
    );
    for (final f in faces) {
      canvas.drawPath(
        f.path(camera, size),
        Paint()
          ..color = f.color
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoomItemPainter oldDelegate) =>
      oldDelegate.item.id != item.id;
}
