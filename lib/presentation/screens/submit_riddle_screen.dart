import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/models/riddle.dart';

class SubmitRiddleScreen extends HookConsumerWidget {
  const SubmitRiddleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riddleController = useTextEditingController();
    final answerController = useTextEditingController();
    final hintController = useTextEditingController();
    final selectedCategory = useState(RiddleCategory.objects);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Riddle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Your Riddle', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextField(
              controller: riddleController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Riddle (must start with "I am")',
                hintText: 'I am...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(labelText: 'Answer'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RiddleCategory>(
              value: selectedCategory.value,
              decoration: const InputDecoration(labelText: 'Category'),
              items: RiddleCategory.values.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat.name));
              }).toList(),
              onChanged: (val) => selectedCategory.value = val ?? RiddleCategory.objects,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hintController,
              decoration: const InputDecoration(labelText: 'Hint (optional)'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Riddle submitted for moderation!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('SUBMIT FOR REVIEW'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
