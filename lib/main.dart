import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Import for date formatting

void main() => runApp(ToDoApp());

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.light(
          primary: Color(0xFF5C6BC0),
          secondary: Color(0xFF7986CB),
          surface: Colors.white,
          background: Color(0xFFF5F7FA),
          error: Color(0xFFE57373),
        ),
      ),
      home: ToDoListPage(),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _dueDate;
  String _selectedPriority = 'Normal';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _editController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Function to get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'Important':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Function to get priority icon
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Urgent':
        return Icons.priority_high;
      case 'Important':
        return Icons.star;
      case 'Normal':
        return Icons.flag;
      default:
        return Icons.flag;
    }
  }

  // Function to sort tasks by priority and date
  void _sortTasks() {
    _tasks.sort((a, b) {
      // First sort by priority
      int priorityA = _getPriorityValue(a['priority']);
      int priorityB = _getPriorityValue(b['priority']);
      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA); // Higher priority first
      }

      // If same priority, sort by date
      if (a['dueDate'] == 'No due date' && b['dueDate'] == 'No due date') {
        return 0;
      }
      if (a['dueDate'] == 'No due date') return 1;
      if (b['dueDate'] == 'No due date') return -1;

      try {
        DateTime dateA = DateFormat('MMM dd, yyyy').parse(a['dueDate']);
        DateTime dateB = DateFormat('MMM dd, yyyy').parse(b['dueDate']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
  }

  // Function to get priority value for sorting
  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'Urgent':
        return 3;
      case 'Important':
        return 2;
      case 'Normal':
        return 1;
      default:
        return 0;
    }
  }

  // Function to pick a date
  Future<void> _pickDueDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  // Function to add task with due date
  void _addTask() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add({
          'text': text,
          'done': false,
          'dueDate': _dueDate != null
              ? DateFormat('MMM dd, yyyy').format(_dueDate!)
              : 'No due date',
          'notes': '',
          'isExpanded': false,
          'priority': _selectedPriority,
        });
        _sortTasks();
        _controller.clear();
        _dueDate = null;
        _selectedPriority = 'Normal';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task added successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  // Function to show edit dialog
  void _showEditDialog(int index) {
    final task = _tasks[index];
    _editController.text = task['text'];
    _notesController.text = task['notes'] ?? '';
    String tempPriority = task['priority'] ?? 'Normal';
    
    // Parse the current due date from the task
    DateTime? tempDueDate;
    if (task['dueDate'] != 'No due date') {
      try {
        tempDueDate = DateFormat('MMM dd, yyyy').parse(task['dueDate']);
      } catch (e) {
        tempDueDate = null;
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Edit Task',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _editController,
                      decoration: InputDecoration(
                        labelText: 'Task Description',
                        hintText: 'Enter your task',
                        prefixIcon: Icon(Icons.task_alt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: TextStyle(fontSize: 16),
                      maxLines: 2,
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempPriority,
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          items: ['Urgent', 'Important', 'Normal'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    _getPriorityIcon(value),
                                    color: _getPriorityColor(value),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setDialogState(() {
                                tempPriority = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Add detailed notes about this task',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: TextStyle(fontSize: 16),
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          tempDueDate == null
                              ? 'Set Due Date'
                              : DateFormat('MMM dd, yyyy').format(tempDueDate!),
                          style: TextStyle(
                            color: tempDueDate == null
                                ? Colors.grey[600]
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: tempDueDate == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Theme.of(context).colorScheme.primary,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              tempDueDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_editController.text.isNotEmpty) {
                              this.setState(() {
                                _tasks[index] = {
                                  'text': _editController.text,
                                  'done': task['done'],
                                  'dueDate': tempDueDate != null
                                      ? DateFormat('MMM dd, yyyy').format(tempDueDate!)
                                      : 'No due date',
                                  'notes': _notesController.text,
                                  'isExpanded': task['isExpanded'],
                                  'priority': tempPriority,
                                };
                                _sortTasks();
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Task updated successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My To-Do List',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Add a new task...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 32),
                        onPressed: _addTask,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickDueDate,
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _dueDate == null
                              ? 'Set Due Date'
                              : DateFormat('MMM dd, yyyy').format(_dueDate!),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriority,
                          items: ['Urgent', 'Important', 'Normal'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    _getPriorityIcon(value),
                                    color: _getPriorityColor(value),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedPriority = newValue;
                              });
                            }
                          },
                          underline: SizedBox(),
                          icon: Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tasks yet!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a task to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Dismissible(
                        key: Key(task['text']),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.red),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          setState(() {
                            _tasks.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task deleted'),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  setState(() {
                                    _tasks.insert(index, task);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(task['priority']).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Checkbox(
                                    value: task['done'],
                                    onChanged: (_) {
                                      setState(() {
                                        task['done'] = !task['done'];
                                      });
                                    },
                                    activeColor: _getPriorityColor(task['priority']),
                                    shape: CircleBorder(),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      _getPriorityIcon(task['priority']),
                                      color: _getPriorityColor(task['priority']),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task['text'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          decoration: task['done']
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task['done']
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          task['dueDate'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (task['notes']?.isNotEmpty ?? false)
                                      IconButton(
                                        icon: Icon(
                                          task['isExpanded'] ?? false
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            task['isExpanded'] = !(task['isExpanded'] ?? false);
                                          });
                                        },
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onPressed: () => _showEditDialog(index),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Delete Task'),
                                              content: Text('Are you sure you want to delete this task?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _tasks.removeAt(index);
                                                    });
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Task deleted'),
                                                        behavior: SnackBarBehavior.floating,
                                                        action: SnackBarAction(
                                                          label: 'UNDO',
                                                          onPressed: () {
                                                            setState(() {
                                                              _tasks.insert(index, task);
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (task['isExpanded'] ?? false)
                                Container(
                                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Divider(),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.note_alt_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Notes:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        task['notes'] ?? 'No notes added',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}