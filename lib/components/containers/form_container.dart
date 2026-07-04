import 'package:flutter/material.dart';

// Equivalente a client/src/components/Containers/FormContainer.jsx
// KeyboardAvoidingView + ScrollView para formularios.

class FormContainer extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const FormContainer({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}
