/// Traduz erros do Firebase e do Dart para mensagens amigáveis em PT-BR.
class ErrorTranslator {
  static String translate(Object error) {
    final s = error.toString();

    // Firebase Auth
    if (s.contains('user-not-found')) {
      return 'Não encontramos uma conta com esse e-mail.';
    }
    if (s.contains('wrong-password')) {
      return 'Senha incorreta. Tente novamente.';
    }
    if (s.contains('invalid-email')) {
      return 'E-mail inválido. Confira e tente de novo.';
    }
    if (s.contains('user-disabled')) {
      return 'Esta conta foi desativada.';
    }
    if (s.contains('too-many-requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos.';
    }
    if (s.contains('email-already-in-use')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (s.contains('weak-password')) {
      return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
    }
    if (s.contains('requires-recent-login')) {
      return 'Por segurança, faça login novamente antes dessa ação.';
    }
    if (s.contains('network-request-failed')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }

    // Firestore
    if (s.contains('permission-denied') ||
        s.contains('Missing or insufficient permissions')) {
      return 'Você não tem permissão para essa ação.';
    }
    if (s.contains('unavailable')) {
      return 'Serviço temporariamente indisponível. Tente mais tarde.';
    }
    if (s.contains('not-found')) {
      return 'Item não encontrado. Ele pode ter sido removido.';
    }
    if (s.contains('failed-precondition')) {
      return 'Operação não permitida no momento.';
    }
    if (s.contains('deadline-exceeded')) {
      return 'A operação demorou muito. Tente novamente.';
    }
    if (s.contains('already-exists')) {
      return 'Este item já existe.';
    }
    if (s.contains('cancelled')) {
      return 'Operação cancelada.';
    }

    // Dart genérico
    if (s.contains('SocketException') ||
        s.contains('UnknownHostException')) {
      return 'Sem conexão. Verifique sua internet.';
    }
    if (s.contains('TimeoutException')) {
      return 'Tempo esgotado. Tente novamente.';
    }

    // Fallback: extrai só a última parte após ']' se houver
    if (s.contains(']')) {
      final clean = s.split(']').last.trim();
      if (clean.length > 0 && clean.length < 200) return clean;
    }

    return 'Não foi possível completar a operação. Tente novamente.';
  }
}
