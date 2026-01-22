// lib/data/dummy_deliveries.dart

import '../models/delivery_model.dart';

final List<DeliveryModel> dummyDeliveries = [
  DeliveryModel(
    id: '1',
    customerName: 'Amit Sharma',
    item: 'Lunch Box',
    address: 'Room 304, Hostel-B, IIT Campus, Near Gate 2, Mumbai',
    latitude: 19.1334,
    longitude: 72.9133,
    eta: '12 mins',
    amount: '99',           // ✅ ADDED
    time: '12:30 PM',       // ✅ ADDED
    status: 'Pending',

    // NEW: Add distance fields
    distBoyToMess: '2.5',
    distMessToCust: '3.2',
    totalDistance: '5.7',

  ),
  DeliveryModel(
    id: '2',
    customerName: 'Priya Patel',
    item: 'Lunch Box',
    address: 'Room 205, Hostel-A, Near Library',
    latitude: 19.1340,
    longitude: 72.9140,
    eta: '20 mins',
    amount: '120',          // ✅ ADDED
    time: '1:00 PM',        // ✅ ADDED
    status: 'Pending',


    // NEW: Add distance fields
    distBoyToMess: '2.5',
    distMessToCust: '3.2',
    totalDistance: '5.7',

  ),
  DeliveryModel(
    id: '3',
    customerName: 'Rahul Verma',
    item: 'Dinner Box',
    address: 'Room 101, PG House, Main Road',
    latitude: 19.1320,
    longitude: 72.9120,
    eta: '25 mins',
    amount: '150',          // ✅ ADDED
    time: '7:30 PM',        // ✅ ADDED
    status: 'Pending',


    // NEW: Add distance fields
    distBoyToMess: '2.5',
    distMessToCust: '3.2',
    totalDistance: '5.7',
  ),
  DeliveryModel(
    id: '4',
    customerName: 'Sneha Desai',
    item: 'Lunch Box',
    address: 'Flat 302, Silver Apartments',
    latitude: 19.1350,
    longitude: 72.9150,
    eta: 'Delivered',
    amount: '99',           // ✅ ADDED
    time: '12:00 PM',       // ✅ ADDED
    status: 'Completed',


    // NEW: Add distance fields
    distBoyToMess: '2.5',
    distMessToCust: '3.2',
    totalDistance: '5.7',
  ),
  DeliveryModel(
    id: '5',
    customerName: 'Karan Singh',
    item: 'Lunch Box',
    address: 'Room 404, Boys Hostel',
    latitude: 19.1325,
    longitude: 72.9125,
    eta: 'Delivered',
    amount: '99',           // ✅ ADDED
    time: '1:15 PM',        // ✅ ADDED
    status: 'Completed',


    // NEW: Add distance fields
    distBoyToMess: '2.5',
    distMessToCust: '3.2',
    totalDistance: '5.7',
  ),
  DeliveryModel(
    id: '6',
    customerName: 'Anjali Gupta',
    item: 'Dinner Box',
    address: 'Room 202, Girls Hostel-C',
    latitude: 19.1345,
    longitude: 72.9145,
    eta: 'Cancelled',
    amount: '120',          // ✅ ADDED
    time: '8:00 PM',        // ✅ ADDED
    status: 'Cancelled',


    // NEW: Add distance fields
    distBoyToMess: '2.5',
    distMessToCust: '3.2',
    totalDistance: '5.7',
  ),
];
