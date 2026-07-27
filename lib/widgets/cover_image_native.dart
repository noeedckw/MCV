import 'dart:io';
import 'package:flutter/material.dart';

Widget buildFileImage(String path) => Image.file(File(path), fit: BoxFit.cover);