import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Todo App with Images',
theme: ThemeData(primarySwatch: Colors.blue),
home: const TodoPage(),
);
}
}

class Task {
int? id;
String title;
bool isDone;
String? imagePath;

Task({this.id, required this.title, this.isDone = false, this.imagePath});

Map<String, dynamic> toMap() {
return {
'id': id,
'title': title,
'isDone': isDone ? 1 : 0,
'imagePath': imagePath,
};
}
}

class TodoPage extends StatefulWidget {
const TodoPage({super.key});

@override
State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
late Database db;
List<Task> tasks = [];
final TextEditingController _controller = TextEditingController();

@override
void initState() {
super.initState();
initDb();
}

Future<void> initDb() async {
final dir = await getApplicationDocumentsDirectory();
db = await openDatabase(join(dir.path, 'tasks.db'),
version: 1, onCreate: (db, version) async {
await db.execute('''
CREATE TABLE tasks(
id INTEGER PRIMARY KEY AUTOINCREMENT,
title TEXT,
isDone INTEGER,
imagePath TEXT
)
''');
});
loadTasks();
}

Future<void> loadTasks() async {
final List<Map<String, dynamic>> maps = await db.query('tasks');
setState(() {
tasks = List.generate(maps.length, (i) {
return Task(
id: maps[i]['id'],
title: maps[i]['title'],
isDone: maps[i]['isDone'] == 1,
imagePath: maps[i]['imagePath'],
);
});
});
}

Future<void> addTask(String title) async {
final id = await db.insert('tasks', Task(title: title).toMap());
_controller.clear();
loadTasks();
}

Future<void> toggleTask(Task task) async {
task.isDone = !task.isDone;
await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
loadTasks();
}

Future<void> deleteTask(int id) async {
await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
loadTasks();
}

Future<void> pickImage(BuildContext context, Task task) async {
final picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);
if (image != null) {
task.imagePath = image.path;
await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
loadTasks();
}
}

Widget buildTaskItem(BuildContext context, Task task) {
return Card(
margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
child: ListTile(
leading: task.imagePath != null
? GestureDetector(
onTap: () {
showDialog(
context: context,
builder: (context) => Dialog(
child: InteractiveViewer(
child: Image.file(File(task.imagePath!)),
),
));
},
child: Image.file(
File(task.imagePath!),
width: 50,
height: 50,
fit: BoxFit.cover,
),
)
: const Icon(Icons.task),
title: Text(task.title,
style: TextStyle(
decoration:
task.isDone ? TextDecoration.lineThrough : TextDecoration.none)),
trailing: Wrap(spacing: 12, children: [
IconButton(
icon: const Icon(Icons.image),
onPressed: () => pickImage(context, task),
),
Checkbox(
value: task.isDone,
onChanged: (_) => toggleTask(task),
),
IconButton(
icon: const Icon(Icons.delete),
onPressed: () => deleteTask(task.id!),
),
]),
),
);
}

void showAddTaskDialog(BuildContext context) {
showDialog(
context: context,
builder: (BuildContext context) {
return AlertDialog(
title: const Text('New Task'),
content: TextField(
controller: _controller,
decoration: const InputDecoration(hintText: 'Enter task title'),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
TextButton(
onPressed: () {
if (_controller.text.trim().isNotEmpty) {
addTask(_controller.text.trim());
Navigator.pop(context);
}
},
child: const Text('Add')),
],
);
},
);
}

@override
Widget build(BuildContext context) {
tasks.sort((a, b) => a.isDone ? 1 : -1);
return Scaffold(
appBar: AppBar(title: const Text('To-Do List')),
body: ListView(
children: tasks.map((task) => buildTaskItem(context, task)).toList(),
),
floatingActionButton: FloatingActionButton(
onPressed: () => showAddTaskDialog(context),
child: const Icon(Icons.add),
),
);
}
}
