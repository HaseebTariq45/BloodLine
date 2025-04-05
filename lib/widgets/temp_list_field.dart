import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

// This is a temporary file with the implementation of the _buildListField method
// to be used in the health_questionnaire_screen.dart file

Widget buildListField({
  required BuildContext context,
  required String title,
  required String hintText,
  required List<String> items,
  required TextEditingController controller,
  required Function() onAdd,
  required Function(int) onRemove,
  required IconData itemIcon,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Add new item section
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade900.withOpacity(0.7)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppConstants.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      
      // List of items
      if (items.isNotEmpty) ...[
        const SizedBox(height: 16),
        ...List.generate(
          items.length,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade700.withOpacity(0.3)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  itemIcon,
                  size: 20,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              title: Text(
                items[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                  size: 20,
                ),
                onPressed: () => onRemove(index),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No items added yet',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ],
  );
} 