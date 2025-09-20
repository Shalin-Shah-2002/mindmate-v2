import 'package:get/get.dart';
import '../models/user_model.dart';

class UserViewModel extends GetxController {
  Rx<UserModel?> user = Rx<UserModel?>(null);

  void setUser(UserModel newUser) {
    user.value = newUser;
  }

  void clearUser() {
    user.value = null;
  }
}
