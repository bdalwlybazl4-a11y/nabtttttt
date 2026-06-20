import 'package:cloud_firestore/cloud_firestore.dart';

void setupFirestore() {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Example: Adding a user
  firestore.collection('users').doc('user_id').set({
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'mood': 'Happy',
    'profileImage': 'https://example.com/profile.jpg',
  });

  // Example: Adding a doctor
  firestore.collection('doctors').doc('doctor_id').set({
    'name': 'Dr. Sarah Smith',
    'email': 'sarah.smith@example.com',
    'specialty': 'Cardiology',
    'qualifications': 'MD, PhD',
    'status': 'verified',
    'profileImage': 'https://example.com/doctor.jpg',
  });

  // Example: Adding an appointment
  firestore.collection('appointments').add({
    'user_id': 'user_id',
    'doctor_id': 'doctor_id',
    'date': '2025-06-20',
    'time': '10:00 AM',
    'location': 'Clinic A',
  });

  // Example: Adding a medication
  firestore.collection('medications').add({
    'user_id': 'user_id',
    'name': 'Paracetamol',
    'dose': '500 mg',
    'schedule': 'Every 8 hours',
  });
}
