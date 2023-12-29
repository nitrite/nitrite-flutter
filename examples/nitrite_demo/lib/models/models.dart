import 'package:nitrite/nitrite.dart';

part 'models.no2.dart';

// Either use EntityDecorator or @Entity
// @Convertable()
// class Todo {
//   @Id(fieldName: 'id')
//   final String id;
//   final String title;
//   bool completed;
//
//   Todo({required this.id, required this.title, this.completed = false});
// }
//
// class TodoDecorator extends EntityDecorator<Todo> {
//   @override
//   EntityId? get idField => EntityId('id');
//
//   @override
//   List<EntityIndex> get indexFields => [
//         const EntityIndex(['title'], IndexType.fullText),
//       ];
//
//   @override
//   String get entityName => 'todo';
// }

@Entity(name: 'todo', indices: [
  Index(fields: ['title'], type: IndexType.fullText),
])
@Convertable()
class Todo with _$TodoEntityMixin {
  @Id(fieldName: 'id')
  final String id;
  final String title;
  bool completed = false;

  Todo({
    required this.id,
    required this.title,
    required this.completed,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          completed == other.completed;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'Todo{id: $id, title: $title, completed: $completed}';
  }
}
