import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:do_an_tot_nghiep/Model/provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const LoginScreen({super.key, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _soDienThoaiController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  bool _matKhauVisible = false;

  @override
  void dispose() {
    _soDienThoaiController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  void _dangNhapTK() async {
  String soDienThoai = _soDienThoaiController.text;
  String matKhau = _matKhauController.text;
  if (soDienThoai.isEmpty || matKhau.isEmpty) {
    _showErrorDialog("Vui lòng nhập đầy đủ thông tin");
    return;
  }

  if (soDienThoai.isEmpty || soDienThoai.length != 10) {
    _showErrorDialog("Số điện thoại phải có đúng 10 chữ số");
    return;
  }

  if (matKhau.isEmpty) {
    _showErrorDialog("Vui lòng nhập mật khẩu");
    return;
  }

  var snapshot = await FirebaseFirestore.instance
      .collection('customers')
      .where('phone', isEqualTo: soDienThoai)
      .get();

  if (snapshot.docs.isEmpty) {
    _showErrorDialog("Số điện thoại không tồn tại");
    return;
  }

 var userDoc = snapshot.docs.first;
var storedPassword = userDoc['password'];

// So sánh mật khẩu nhập vào với mật khẩu đã lưu
if (matKhau != storedPassword) {
  _showErrorDialog("Mật khẩu không chính xác");
  return;
}

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  authProvider.login(soDienThoai);
  widget.onSuccess();

}


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(padding: EdgeInsets.all(16.0)),
        TextField(
          controller: _soDienThoaiController,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            fillColor: Colors.white,
            filled: true,
          ),
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: _matKhauController,
          obscureText: !_matKhauVisible,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            fillColor: Colors.white,
            filled: true,
            suffixIcon: IconButton(
              icon: Icon(
                _matKhauVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _matKhauVisible = !_matKhauVisible;
                });
              },
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            _dangNhapTK();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
