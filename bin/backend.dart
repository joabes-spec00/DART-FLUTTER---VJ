import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------
// CONFIGURAÇÕES DO JOGO
// ---------------------------------------------------------------

/// Marcador que indica onde o aluno deve preencher o código.
const String marcador = '___BLANK___';

/// Pontos perdidos a cada resposta errada (o total nunca fica abaixo de 0).
const int penalidade = 5;

/// Administradores do jogo (nomes em minúsculas).
const Set<String> admins = {'joabes', 'vyctor'};

bool ehAdmin(String id) => admins.contains(id.trim().toLowerCase());

// ---------------------------------------------------------------
// MODELO DO DESAFIO
// ---------------------------------------------------------------

class Desafio {
  final int id;
  final String title;
  final String description;
  final String codeTemplate;
  final List<String> hints;
  final String expectedOutput;
  final String difficulty; // easy | medium | hard

  /// Para cada lacuna, a lista de respostas aceitas.
  /// Esta lista NUNCA é enviada ao aluno.
  final List<List<String>> respostas;

  Desafio({
    required this.id,
    required this.title,
    required this.description,
    required this.codeTemplate,
    required this.hints,
    required this.expectedOutput,
    required this.difficulty,
    required this.respostas,
  });

  /// Quantidade de lacunas no código.
  int get lacunas => marcador.allMatches(codeTemplate).length;

  /// Pontos base: multiplicados pelas estrelas (1 a 3) ao acertar.
  int get pontosBase {
    if (difficulty == 'hard') return 20;
    if (difficulty == 'medium') return 15;
    return 10;
  }

  /// Versão enviada ao aluno (sem as respostas).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'codeTemplate': codeTemplate,
        'hints': hints,
        'expectedOutput': expectedOutput,
        'difficulty': difficulty,
        'blanks': lacunas,
        'basePoints': pontosBase,
      };
}

// ---------------------------------------------------------------
// DESAFIOS (tema: Dart | nível: iniciante | variáveis, laços e funções)
// ---------------------------------------------------------------

final List<Desafio> desafios = [
  Desafio(
    id: 1,
    title: 'Declarando uma variável de texto',
    description: 'Complete o tipo da variável para guardar um texto.',
    codeTemplate: r'''void main() {
  ___BLANK___ nome = 'Ana';
  print(nome);
}''',
    hints: [
      'Textos em Dart usam um tipo que começa com letra maiúscula.',
      'O tipo é String (com S maiúsculo).',
    ],
    expectedOutput: 'Ana',
    difficulty: 'easy',
    respostas: [
      ['String', 'var', 'final'],
    ],
  ),
  Desafio(
    id: 2,
    title: 'Somando dois números',
    description: 'Complete a operação para somar a e b.',
    codeTemplate: r'''void main() {
  int a = 7;
  int b = 5;
  int soma = a ___BLANK___ b;
  print(soma);
}''',
    hints: [
      'Você precisa de um operador matemático.',
      'O operador de soma é o símbolo +.',
    ],
    expectedOutput: '12',
    difficulty: 'easy',
    respostas: [
      ['+'],
    ],
  ),
  Desafio(
    id: 3,
    title: 'Contando com for',
    description: 'Complete o limite do laço para imprimir de 1 até 5.',
    codeTemplate: r'''void main() {
  for (int i = 1; i <= ___BLANK___; i++) {
    print(i);
  }
}''',
    hints: [
      'O laço continua enquanto i <= limite.',
      'Como o último número impresso é 5, o limite é 5.',
    ],
    expectedOutput: '1\n2\n3\n4\n5',
    difficulty: 'easy',
    respostas: [
      ['5'],
    ],
  ),
  Desafio(
    id: 4,
    title: 'Tomando uma decisão',
    description: 'Complete a palavra que trata o caso contrário do if.',
    codeTemplate: r'''void main() {
  int nota = 8;
  if (nota >= 7) {
    print('Aprovado');
  } ___BLANK___ {
    print('Reprovado');
  }
}''',
    hints: [
      'Essa palavra executa quando o if é falso.',
      'A palavra é else.',
    ],
    expectedOutput: 'Aprovado',
    difficulty: 'medium',
    respostas: [
      ['else'],
    ],
  ),
  Desafio(
    id: 5,
    title: 'Repetindo com while',
    description: 'Complete a palavra do laço que conta de 3 até 1.',
    codeTemplate: r'''void main() {
  int contador = 3;
  ___BLANK___ (contador > 0) {
    print(contador);
    contador--;
  }
}''',
    hints: [
      'Esse laço repete enquanto a condição for verdadeira.',
      'A palavra é while.',
    ],
    expectedOutput: '3\n2\n1',
    difficulty: 'medium',
    respostas: [
      ['while'],
    ],
  ),
  Desafio(
    id: 6,
    title: 'Criando uma função',
    description: 'Complete o tipo de retorno da função dobro.',
    codeTemplate: r'''___BLANK___ dobro(int numero) {
  return numero * 2;
}

void main() {
  print(dobro(4));
}''',
    hints: [
      'O tipo de retorno vem antes do nome da função.',
      'A função devolve um número inteiro: int.',
    ],
    expectedOutput: '8',
    difficulty: 'medium',
    respostas: [
      ['int', 'num'],
    ],
  ),
  Desafio(
    id: 7,
    title: 'Somando uma lista',
    description:
        'Complete as duas lacunas para somar todos os números da lista.',
    codeTemplate: r'''int somaLista(List<int> numeros) {
  int total = 0;
  for (int n ___BLANK___ numeros) {
    total += ___BLANK___;
  }
  return total;
}

void main() {
  print(somaLista([1, 2, 3, 4]));
}''',
    hints: [
      'Para percorrer cada item de uma lista, use a forma for (x in lista).',
      'Primeira lacuna: in. Segunda lacuna: o item atual do laço.',
    ],
    expectedOutput: '10',
    difficulty: 'hard',
    respostas: [
      ['in'],
      ['n'],
    ],
  ),
];

// ---------------------------------------------------------------
// PROGRESSO DOS ALUNOS (guardado em memória enquanto o servidor roda)
// ---------------------------------------------------------------

class Progresso {
  int pontos = 0;

  /// id do desafio -> tentativas feitas
  final Map<int, int> tentativas = {};

  /// id do desafio -> estrelas ganhas (só desafios concluídos)
  final Map<int, int> estrelas = {};
}

final Map<String, Progresso> alunos = {};

Map<String, dynamic> progressoParaJson(String studentId, Progresso p) {
  final concluidos =
      p.estrelas.entries.map((e) => {'id': e.key, 'stars': e.value}).toList();

  return {
    'studentId': studentId,
    'isAdmin': ehAdmin(studentId),
    'points': p.pontos,
    'completed': concluidos,
    'attempts': p.tentativas.map((k, v) => MapEntry(k.toString(), v)),
    'totalChallenges': desafios.length,
    'completedCount': concluidos.length,
    'percent': (concluidos.length * 100 / desafios.length).round(),
  };
}

// ---------------------------------------------------------------
// FUNÇÕES AUXILIARES
// ---------------------------------------------------------------

/// Remove espaços extras para comparar respostas.
String normalizar(String texto) =>
    texto.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Confere se as respostas enviadas batem com as aceitas em cada lacuna.
/// A comparação diferencia maiúsculas de minúsculas, como o Dart faz.
bool conferir(Desafio desafio, List<String> enviadas) {
  if (enviadas.length != desafio.respostas.length) return false;

  for (var i = 0; i < desafio.respostas.length; i++) {
    final aceitas = desafio.respostas[i].map(normalizar).toList();
    if (!aceitas.contains(normalizar(enviadas[i]))) return false;
  }
  return true;
}

Desafio? buscarDesafio(int? id) {
  for (final d in desafios) {
    if (d.id == id) return d;
  }
  return null;
}

Future<void> responderJson(
    HttpRequest request, int status, Object corpo) async {
  final resposta = request.response;
  resposta.statusCode = status;
  resposta.headers.contentType = ContentType.json;
  resposta.write(jsonEncode(corpo));
  await resposta.close();
}

// ---------------------------------------------------------------
// ROTAS
// ---------------------------------------------------------------

/// GET / -> entrega a página do jogo (public/index.html)
Future<void> servirPagina(HttpRequest request) async {
  final arquivo = File('public/index.html');

  if (!await arquivo.exists()) {
    await responderJson(request, HttpStatus.notFound, {
      'erro': 'Arquivo public/index.html não encontrado. '
          'Rode "dart run" dentro da pasta backend.'
    });
    return;
  }

  final resposta = request.response;
  resposta.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
  resposta.write(await arquivo.readAsString());
  await resposta.close();
}

/// POST /api/challenges/:id/check
/// Corpo: { "studentId": "ana", "answers": ["String"] }
Future<void> verificarDesafio(HttpRequest request, String idTexto) async {
  final desafio = buscarDesafio(int.tryParse(idTexto));
  if (desafio == null) {
    await responderJson(
        request, HttpStatus.notFound, {'erro': 'Desafio não encontrado'});
    return;
  }

  // Lê e valida o JSON enviado pelo aluno.
  dynamic dados;
  try {
    dados = jsonDecode(await utf8.decoder.bind(request).join());
  } catch (_) {
    await responderJson(
        request, HttpStatus.badRequest, {'erro': 'JSON inválido'});
    return;
  }

  if (dados is! Map ||
      dados['answers'] is! List ||
      (dados['studentId'] ?? '').toString().trim().isEmpty) {
    await responderJson(request, HttpStatus.badRequest,
        {'erro': 'Envie studentId e answers (lista de respostas)'});
    return;
  }

  final studentId = dados['studentId'].toString().trim().toLowerCase();
  final respostas =
      (dados['answers'] as List).map((e) => e.toString()).toList();
  final progresso = alunos.putIfAbsent(studentId, () => Progresso());

  // Desafio já concluído: não ganha nem perde pontos de novo.
  if (progresso.estrelas.containsKey(desafio.id)) {
    await responderJson(request, HttpStatus.ok, {
      'correct': true,
      'alreadyCompleted': true,
      'message': 'Você já concluiu este desafio.',
      'pointsDelta': 0,
      'totalPoints': progresso.pontos,
      'stars': progresso.estrelas[desafio.id],
      'attempts': progresso.tentativas[desafio.id] ?? 0,
      'expectedOutput': desafio.expectedOutput,
    });
    return;
  }

  final tentativa = (progresso.tentativas[desafio.id] ?? 0) + 1;
  progresso.tentativas[desafio.id] = tentativa;

  // ACERTOU: estrelas dependem das tentativas (1ª = 3, 2ª = 2, depois = 1).
  if (conferir(desafio, respostas)) {
    final estrelas = tentativa == 1 ? 3 : (tentativa == 2 ? 2 : 1);
    final ganho = desafio.pontosBase * estrelas;

    progresso.pontos += ganho;
    progresso.estrelas[desafio.id] = estrelas;

    await responderJson(request, HttpStatus.ok, {
      'correct': true,
      'alreadyCompleted': false,
      'message': 'Resposta correta!',
      'pointsDelta': ganho,
      'totalPoints': progresso.pontos,
      'stars': estrelas,
      'attempts': tentativa,
      'expectedOutput': desafio.expectedOutput,
    });
    return;
  }

  // ERROU: perde pontos (sem passar de 0) e recebe uma dica.
  final perda = penalidade > progresso.pontos ? progresso.pontos : penalidade;
  progresso.pontos -= perda;

  final posicaoDica = tentativa - 1 < desafio.hints.length
      ? tentativa - 1
      : desafio.hints.length - 1;

  await responderJson(request, HttpStatus.ok, {
    'correct': false,
    'alreadyCompleted': false,
    'message': 'Resposta incorreta.',
    'hint': desafio.hints[posicaoDica],
    'pointsDelta': -perda,
    'totalPoints': progresso.pontos,
    'stars': 0,
    'attempts': tentativa,
  });
}

/// GET /api/admin/panel?adminId=joabes
/// Devolve o ranking de todos os alunos e as respostas de cada desafio.
Future<void> painelAdmin(HttpRequest request) async {
  final adminId =
      (request.uri.queryParameters['adminId'] ?? '').trim().toLowerCase();

  if (!ehAdmin(adminId)) {
    await responderJson(request, HttpStatus.forbidden,
        {'erro': 'Acesso permitido apenas para administradores'});
    return;
  }

  final ranking = alunos.entries.map((e) {
    final p = e.value;
    return {
      'studentId': e.key,
      'isAdmin': ehAdmin(e.key),
      'points': p.pontos,
      'completedCount': p.estrelas.length,
      'stars': p.estrelas.values.fold<int>(0, (soma, v) => soma + v),
    };
  }).toList();

  // Maior pontuação primeiro.
  ranking.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

  final respostas = desafios
      .map((d) => {
            'id': d.id,
            'title': d.title,
            'answers': d.respostas.map((r) => r.join(' ou ')).toList(),
          })
      .toList();

  await responderJson(request, HttpStatus.ok, {
    'students': ranking,
    'challenges': respostas,
  });
}

/// POST /api/admin/reset
/// Corpo: { "adminId": "joabes", "studentId": "ana" }
Future<void> resetarAluno(HttpRequest request) async {
  dynamic dados;
  try {
    dados = jsonDecode(await utf8.decoder.bind(request).join());
  } catch (_) {
    await responderJson(
        request, HttpStatus.badRequest, {'erro': 'JSON inválido'});
    return;
  }

  if (dados is! Map ||
      !ehAdmin((dados['adminId'] ?? '').toString()) ||
      (dados['studentId'] ?? '').toString().trim().isEmpty) {
    await responderJson(request, HttpStatus.forbidden,
        {'erro': 'Apenas administradores podem zerar o progresso'});
    return;
  }

  final studentId = dados['studentId'].toString().trim().toLowerCase();
  alunos.remove(studentId);

  await responderJson(request, HttpStatus.ok, {'ok': true});
}

/// Decide qual rota atender.
Future<void> tratar(HttpRequest request) async {
  final resposta = request.response;

  // Permite o acesso de outras origens (CORS).
  resposta.headers.set('Access-Control-Allow-Origin', '*');
  resposta.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  resposta.headers.set('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method == 'OPTIONS') {
    resposta.statusCode = HttpStatus.noContent;
    await resposta.close();
    return;
  }

  final partes = request.uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final metodo = request.method;

  // GET /
  if (metodo == 'GET' && partes.isEmpty) {
    await servirPagina(request);
    return;
  }

  // GET /api/challenges
  if (metodo == 'GET' &&
      partes.length == 2 &&
      partes[0] == 'api' &&
      partes[1] == 'challenges') {
    await responderJson(
        request, HttpStatus.ok, desafios.map((d) => d.toJson()).toList());
    return;
  }

  // POST /api/challenges/:id/check
  if (metodo == 'POST' &&
      partes.length == 4 &&
      partes[0] == 'api' &&
      partes[1] == 'challenges' &&
      partes[3] == 'check') {
    await verificarDesafio(request, partes[2]);
    return;
  }

  // GET /api/progress/:studentId
  if (metodo == 'GET' &&
      partes.length == 3 &&
      partes[0] == 'api' &&
      partes[1] == 'progress') {
    final studentId = partes[2].trim().toLowerCase();
    final progresso = alunos[studentId] ?? Progresso();
    await responderJson(
        request, HttpStatus.ok, progressoParaJson(studentId, progresso));
    return;
  }

  // GET /api/admin/panel
  if (metodo == 'GET' &&
      partes.length == 3 &&
      partes[0] == 'api' &&
      partes[1] == 'admin' &&
      partes[2] == 'panel') {
    await painelAdmin(request);
    return;
  }

  // POST /api/admin/reset
  if (metodo == 'POST' &&
      partes.length == 3 &&
      partes[0] == 'api' &&
      partes[1] == 'admin' &&
      partes[2] == 'reset') {
    await resetarAluno(request);
    return;
  }

  await responderJson(
      request, HttpStatus.notFound, {'erro': 'Rota não encontrada'});
}

// ---------------------------------------------------------------
// INÍCIO DO SERVIDOR
// ---------------------------------------------------------------

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, int.parse(Platform.environment['PORT'] ?? '8080'));
  print('Servidor rodando em http://localhost:${server.port}');

  await for (final request in server) {
    try {
      await tratar(request);
    } catch (e) {
      // Um erro numa requisição não derruba o servidor.
      print('Erro ao atender ${request.uri}: $e');
      try {
        await responderJson(request, HttpStatus.internalServerError,
            {'erro': 'Erro interno no servidor'});
      } catch (_) {}
    }
  }
}