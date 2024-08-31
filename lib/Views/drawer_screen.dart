import 'package:do_an_tot_nghiep/Model/provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final phoneNumber = authProvider.phoneNumber;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 2.2 / 3,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(194, 101, 30, 0.871),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Cake & Coffee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('customers')
                            .where('phone', isEqualTo: authProvider.phoneNumber)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox();
                          } else if (snapshot.hasError) {
                            return SizedBox();
                          } else if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return SizedBox();
                          }

                          final customerData = snapshot.data!.docs[0].data()
                              as Map<String, dynamic>;
                          final name = customerData['name'];

                          return Text(
                            'Xin chào $name,',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .where('phone', isEqualTo: phoneNumber)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text('Đang tải...'),
                  );
                } else if (snapshot.hasError) {
                  return ListTile(
                    title: Text('Lỗi: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return ListTile(
                    title: Text('Không có thông tin'),
                  );
                }

                final customerData =
                    snapshot.data!.docs[0].data() as Map<String, dynamic>;
                final name = customerData['name'];
                final phone = customerData['phone'];
                final point = customerData['point'];
                final currentPassword = customerData['password'];

                return Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.only(left: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Thông tin thành viên: ',
                        style: TextStyle(
                          color: Color.fromRGBO(194, 101, 30, 0.871),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildListTile(
                        Icons.account_circle, 'Tên thành viên: $name'),
                    const SizedBox(height: 10),
                    buildListTile(Icons.phone, 'SĐT: $phone'),
                    const SizedBox(height: 10),
                    buildListTile(Icons.thumb_up, 'Điểm thành viên: $point'),
                    const SizedBox(height: 10),
                    buildListTile(Icons.lock, 'Đổi mật khẩu', onTap: () {
                      _showChangePasswordDialog(context, phoneNumber, currentPassword);
                    }),
                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text(
                        'Đổi tài khoản',
                        style: TextStyle(
                          color: Color.fromARGB(255, 184, 113, 6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        authProvider.clearPhoneNumber();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, String phoneNumber, String currentPassword) {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu cũ',
                fillColor: Colors.white,
                filled: true,
              ),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                fillColor: Colors.white,
                filled: true,
              ),
              obscureText: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(16),
              ],
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                fillColor: Colors.white,
                filled: true,
              ),
              obscureText: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(16),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              String oldPassword = oldPasswordController.text;
              String newPassword = newPasswordController.text;
              String confirmPassword = confirmPasswordController.text;

              // Ràng buộc mật khẩu
              if (newPassword.length < 8 || newPassword.length > 15 || 
                  !RegExp(r'^(?=.*[A-Z])(?=.*[\W_]).*$').hasMatch(newPassword)) {
                _showErrorDialog(context, 'Mật khẩu mới phải chứa từ 8 đến 15 ký tự, ít nhất 1 chữ cái viết hoa và 1 ký tự đặc biệt!');
                return;
              }

              if (newPassword != confirmPassword) {
                _showErrorDialog(context, 'Mật khẩu mới không khớp');
                return;
              }

              if (oldPassword != currentPassword) {
                _showErrorDialog(context, 'Mật khẩu cũ không đúng');
                return;
              }

              try {
                // Lấy tài liệu với phoneNumber
                var querySnapshot = await FirebaseFirestore.instance
                    .collection('customers')
                    .where('phone', isEqualTo: phoneNumber)
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  final docId = querySnapshot.docs[0].id;

                  // Cập nhật mật khẩu
                  await FirebaseFirestore.instance
                      .collection('customers')
                      .doc(docId)
                      .update({'password': newPassword});

                  Navigator.pop(context);
                  _showSuccessDialog(context, 'Đổi mật khẩu thành công');
                } else {
                  _showErrorDialog(context, 'Số điện thoại không tồn tại.');
                }
              } catch (e) {
                _showErrorDialog(context, 'Đổi mật khẩu không thành công: ${e.toString()}');
              }
            },
            child: Text('Xác nhận'),
          ),
        ],
      );
    },
  );
}


  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thành công'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

Widget buildListTile(IconData icon, String text, {VoidCallback? onTap}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 16.0),
          Text(text),
        ],
      ),
    ),
  );
}
