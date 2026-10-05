import 'dart:io';
import 'dart:convert';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Servidor rodando em http://localhost:${server.port}');

  await for (HttpRequest request in server) {
    request.response.headers.contentType = ContentType.json;

    if (request.uri.path == '/' && request.method == 'GET') {
      request.response.write(jsonEncode({'mensagem': 'Backend funcionando!'}));
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'erro': 'Rota não encontrada'}));
    }

    await request.response.close();
  }
}