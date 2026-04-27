import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final int colorValue;
  final String classCode;
  final String teacherId;
  final String teacherName;
  final int studentCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ClassModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.colorValue,
    required this.classCode,
    required this.teacherId,
    required this.teacherName,
    this.studentCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  Color get color => Color(colorValue);

  factory ClassModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ClassModel(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      colorValue: data['colorValue'] ?? 0xFF6F5AAA,
      classCode: data['classCode'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      studentCount: data['studentCount'] ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'description': description,
      'colorValue': colorValue,
      'classCode': classCode,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentCount': studentCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
