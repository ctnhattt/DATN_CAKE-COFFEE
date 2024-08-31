import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_tot_nghiep/Model/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  RegisterScreen({required this.onSuccess});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _tenKhachHangController = TextEditingController();
  final TextEditingController _soDienThoaiController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  final TextEditingController _nhapLaiMatKhauController = TextEditingController();

  @override
  void dispose() {
    _tenKhachHangController.dispose();
    _soDienThoaiController.dispose();
    _matKhauController.dispose();
    _nhapLaiMatKhauController.dispose();
    super.dispose();
  }

  void _dangKyTK() async {
    String tenKhachHang = _tenKhachHangController.text;
    String soDienThoai = _soDienThoaiController.text;
    String matKhau = _matKhauController.text;
    String nhapLaiMatKhau = _nhapLaiMatKhauController.text;
    
     if (tenKhachHang.isEmpty || soDienThoai.isEmpty || matKhau.isEmpty || nhapLaiMatKhau.isEmpty) {
    _showErrorDialog("Vui lòng nhập đầy đủ thông tin");
    return;
  }

    if (soDienThoai.length != 10 || !isNumeric(soDienThoai)) {
      _showErrorDialog("Số điện thoại phải có 10 số!");
      return;
    }
     if (!soDienThoai.startsWith('03') &&
      !soDienThoai.startsWith('07') &&
      !soDienThoai.startsWith('09') &&
      !soDienThoai.startsWith('02')) {
    _showErrorDialog("Số điện thoại phải có đầu số 03, 07, 09, hoặc 02!");
    return;
  }

    if (matKhau != nhapLaiMatKhau) {
      _showErrorDialog("Mật khẩu nhập lại không khớp");
      return;
    }

    
    if (matKhau.length < 8 || matKhau.length > 15 || 
        !RegExp(r'^(?=.*[A-Z])(?=.*[\W_]).*$').hasMatch(matKhau)) {
      _showErrorDialog("Mật khẩu phải chứa từ 8 đến 15 ký tự, ít nhất 1 chữ cái viết hoa và 1 ký tự đặc biệt!");
      return;
    }

    try {
       var customerSnapshot = await FirebaseFirestore.instance
      .collection('customers')
      .where('phone', isEqualTo: soDienThoai)
      .get();

  if (customerSnapshot.docs.isEmpty) {
        Map<String, dynamic> customerData = {
          'name': tenKhachHang,
          'phone': soDienThoai,
          'password': matKhau,
          'point': 0,
          'create_time': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('customers')
            .doc()
            .set(customerData);

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.login(soDienThoai);
        widget.onSuccess();
        
      } else {
        _showErrorDialog("Số điện thoại đã được đăng ký trước đó!");
      }
    } catch (e) {
      _showErrorDialog("Đăng ký không thành công!");
    }
  }

  bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _tenKhachHangController,
          decoration: const InputDecoration(
            labelText: 'Tên khách hàng',
            fillColor: Colors.white,
            filled: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(
                r'[!@#<>?":_~;[\]\\|=+)(*&^%0-9-]')),
          ],
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: _soDienThoaiController,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            fillColor: Colors.white,
            filled: true,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: _matKhauController,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu',
            fillColor: Colors.white,
            filled: true,
          ),
          obscureText: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
          ],
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: _nhapLaiMatKhauController,
          decoration: const InputDecoration(
            labelText: 'Nhập lại mật khẩu',
            fillColor: Colors.white,
            filled: true,
          ),
          obscureText: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
          ],
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: _dangKyTK,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Đăng ký',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
