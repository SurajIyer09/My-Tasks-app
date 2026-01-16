import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const TodoApp());
}

// --- 1. THEME & APP SETUP ---
class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern Todo',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        fontFamily: 'Roboto',
      ),
      home: const TodoListScreen(),
    );
  }
}

// --- 2. MODEL ---
enum Priority { low, medium, high }

class Todo {
  String id;
  String title;
  bool isCompleted;
  Priority priority;
  DateTime? dueTime;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = Priority.medium,
    this.dueTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'priority': priority.index,
    'dueTime': dueTime?.toIso8601String(),
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? DateTime.now().toString(),
      title: json['title'],
      isCompleted: json['isCompleted'],
      priority: Priority.values[json['priority'] ?? 1],
      dueTime: json['dueTime'] != null ? DateTime.parse(json['dueTime']) : null,
    );
  }
}

// --- 3. MAIN SCREEN ---
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  final TextEditingController _titleController = TextEditingController();

  // Dialog State
  Priority _selectedPriority = Priority.medium;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // --- PERSISTENCE ---
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todo_list_v3', encodedData);
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('todo_list_v3');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      setState(() {
        _todos = decodedData.map((item) => Todo.fromJson(item)).toList();
      });
    }
  }

  // --- LOGIC ---
  void _handleTaskCompletion(int index) {
    setState(() {
      _todos[index].isCompleted = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _todos.removeAt(index);
        });
        _saveTodos();
      }
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final Todo item = _todos.removeAt(oldIndex);
      _todos.insert(newIndex, item);
    });
    _saveTodos();
  }

  // --- DIALOG ---
  void _showTaskDialog({Todo? todoToEdit, int? index}) {
    if (todoToEdit != null) {
      _titleController.text = todoToEdit.title;
      _selectedPriority = todoToEdit.priority;
      if (todoToEdit.dueTime != null) {
        _selectedTime = TimeOfDay.fromDateTime(todoToEdit.dueTime!);
      } else {
        _selectedTime = null;
      }
    } else {
      _titleController.clear();
      _selectedPriority = Priority.medium;
      _selectedTime = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252525),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                todoToEdit == null ? 'Create Task' : 'Edit Task',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.purpleAccent,
                    decoration: InputDecoration(
                      hintText: "What needs doing?",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF303030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purpleAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text("Priority:", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 10),
                      ...Priority.values.map((p) {
                        final bool isSelected = _selectedPriority == p;
                        return GestureDetector(
                          onTap: () => setDialogState(() => _selectedPriority = p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? _getPriorityColor(p)
                                  : _getPriorityColor(p).withOpacity(0.2),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }),
                      const Spacer(),

                      IconButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => _selectedTime = picked);
                          }
                        },
                        icon: Icon(
                          Icons.access_time_filled,
                          color: _selectedTime != null ? Colors.purpleAccent : Colors.grey,
                          size: 28,
                        ),
                      ),
                      if (_selectedTime != null)
                        Text(
                          _selectedTime!.format(context),
                          style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBB86FC),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (_titleController.text.isNotEmpty) {
                      DateTime? finalDateTime;
                      if (_selectedTime != null) {
                        final now = DateTime.now();
                        finalDateTime = DateTime(
                            now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);
                      }

                      setState(() {
                        if (todoToEdit != null && index != null) {
                          _todos[index].title = _titleController.text;
                          _todos[index].priority = _selectedPriority;
                          _todos[index].dueTime = finalDateTime;
                        } else {
                          _todos.add(Todo(
                            id: DateTime.now().toString(),
                            title: _titleController.text,
                            priority: _selectedPriority,
                            dueTime: finalDateTime,
                          ));
                        }
                      });
                      _saveTodos();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(todoToEdit == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high: return const Color(0xFFFF5252);
      case Priority.medium: return const Color(0xFFFFAB40);
      case Priority.low: return const Color(0xFF69F0AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- CLEAN HEADER (One button removed) ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("My Tasks",
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text("Focus on your day",
                            style: TextStyle(fontSize: 16, color: Colors.white54)),
                      ],
                    ),
                    // Removed the duplicate 'Add' button Container here
                  ],
                ),
              ),

              // --- TASK LIST ---
              Expanded(
                child: _todos.isEmpty
                    ? Center(
                  child: Text("Relax, you're all caught up.",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                )
                    : ReorderableListView.builder(
                  onReorder: _onReorder,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _todos.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(_todos[index], index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFBB86FC),
        foregroundColor: Colors.black,
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text("New Task", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTaskCard(Todo todo, int index) {
    return Dismissible(
      key: ValueKey(todo.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteTask(index),
      child: GestureDetector(
        onTap: () => _showTaskDialog(todoToEdit: todo, index: index),
        child: Container(
          key: ValueKey(todo.id),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF252525).withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: _getPriorityColor(todo.priority), width: 6),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _handleTaskCompletion(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(color: todo.isCompleted ? Colors.green : Colors.grey, width: 2),
                  ),
                  child: todo.isCompleted ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedOpacity(
                      opacity: todo.isCompleted ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: Colors.white,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                    if (todo.dueTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(todo.dueTime!),
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                  ],  
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}