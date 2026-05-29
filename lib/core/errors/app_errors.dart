import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// User-facing error text in Russian (no raw exception dumps).
String friendlyErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'keychain-error':
        return 'Ошибка Keychain. В Xcode выберите Team в Signing или сбросьте симулятор.';
      case 'network-request-failed':
        return 'Нет сети. Проверьте интернет и эмуляторы Firebase.';
      default:
        return error.message ?? 'Ошибка входа';
    }
  }
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'not-found':
        return 'Код не найден';
      case 'permission-denied':
        return error.message ?? 'Нет доступа';
      case 'already-exists':
        return error.message ?? 'Уже выполнено';
      case 'failed-precondition':
        return error.message ?? 'Действие недоступно';
      case 'deadline-exceeded':
        return 'Срок кода истёк';
      case 'invalid-argument':
        return error.message ?? 'Проверьте введённые данные';
      case 'unauthenticated':
        return 'Сначала войдите в приложение';
      case 'internal':
        return 'Ошибка сервера. Перезапустите эмуляторы functions.';
      default:
        return error.message ?? 'Ошибка сервера';
    }
  }
  if (error is PlatformException) {
    final code = error.code;
    if (code.contains('permission-denied')) {
      return 'Нет доступа к данным. Перезапустите приложение.';
    }
    return error.message ?? 'Ошибка: $code';
  }
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Нет доступа к данным';
  }
  if (text.contains('network')) {
    return 'Проблема с сетью';
  }
  return 'Что-то пошло не так. Попробуйте ещё раз.';
}
