import 'package:flutter/material.dart';

/// generic TextEditingController & Model Record

class ControllerRecord<T> {
  final TextEditingController controller;
  T? model;

  ControllerRecord({required this.controller, this.model});

  void dispose() {
    controller.dispose();
  }

  void disposeAll() {
    controller.dispose();
    model = null;
  }
}
