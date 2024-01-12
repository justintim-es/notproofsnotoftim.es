import 'dart:convert';
import 'dart:isolate';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exempla/constantes.dart';
import '../exempla/errors.dart';
import '../exempla/gladiator.dart';
import '../exempla/obstructionum.dart';
import '../exempla/pera.dart';
import '../exempla/petitio/clavis_par.dart';
import '../exempla/responsio/propter_notitia.dart';
import '../exempla/utils.dart';
import 'dart:io';
import '../server.dart';

Future<Response> propterSubmittere(Request req) async {
  String publica = req.params['publica-clavis']!;
  Directory directorium =
      Directory('vincula/${argumentis!.obstructionumDirectorium}');
  List<Obstructionum> lo = await Obstructionum.getBlocks(directorium);
  if (await Pera.isPublicaClavisDefended(publica, lo)) {
    return Response.badRequest(
        body: json.encode({
      "code": 0,
      "nuntius": "Publica clavis iam defendi",
      "message": "Public key  already defended"
    }));
  }
  if (par!.rationibus.any((ap) => ap.interiore.publicaClavis == publica)) {
    return Response.badRequest(
          body: json.encode({
        "code": 1,
        "nuntius": "publica clavem iam in piscinam",
        "english": "Public key is already in pool"
    }));
  }
  ReceivePort acciperePortus = ReceivePort();
  InteriorePropter interioreRationem = InteriorePropter(publica);
  isolates.propterIsolates[interioreRationem.publicaClavis] = await Isolate.spawn(
      Propter.quaestum,
      List<dynamic>.from([interioreRationem, acciperePortus.sendPort]));
  acciperePortus.listen((propter) {
    par!.syncPropter(propter as Propter);
  });
  return Response.ok(json.encode({
    "nuntius": 'clavis publica in piscina defendi exspectat',
    "message": "public key is waiting in the pool to be defended"
  }));
}


Future<Response> propterSubmittereMulti(Request req) async {
  List<String> lpc = List<String>.from(json.decode(await req.readAsString()));
  Directory directorium =
      Directory('vincula/${argumentis!.obstructionumDirectorium}');
  List<Obstructionum> lo = await Obstructionum.getBlocks(directorium);
  for (String pc in lpc) {
    if (await Pera.isPublicaClavisDefended(pc, lo)) {
      return Response.badRequest(body: json.encode(BadRequest(code: 0, nuntius: 'the public key $pc iam defenditur', message: 'the public key $pc is already defended')));
    }
    if (par!.rationibus.any((ap) => ap.interiore.publicaClavis == pc)) {
      return Response.badRequest(body: json.encode(BadRequest(code: 0, nuntius: 'clavis publica $pc iam in piscina defendi', message: 'the public key $pc is already in the pool to be defended')));
    }
  }
  ReceivePort rp = ReceivePort();
  for (String pc in lpc) {
    InteriorePropter interiore = InteriorePropter(pc);
    isolates.propterIsolates[interiore.publicaClavis] = await Isolate.spawn(Propter.quaestum, List<dynamic>.from([interiore, rp.sendPort]));
  }
  rp.listen((propter) {
    par!.syncPropter(propter as Propter);
  });
  return Response.ok(json.encode({
    "nuntius": "omnes claves publicas piscinam defendi intraverunt",
    "message": "all public keys have entered the pool to be defended"
  }));
}
Future<Response> propterStatus(Request req) async {
  String publica = req.params['publica-clavis']!;
  Directory directory =
      Directory('vincula/${argumentis!.obstructionumDirectorium}');
  List<Obstructionum> obs = [];
  for (int i = 0; i < directory.listSync().length; i++) {
    await for (String obstructionum in Utils.fileAmnis(
        File('${directory.path}${Constantes.caudices}$i.txt'))) {
      obs.add(Obstructionum.fromJson(
          json.decode(obstructionum) as Map<String, dynamic>));
    }
  }
  for (InterioreObstructionum interiore
      in obs.map((o) => o.interiore)) {
    // List<GladiatorOutput> outputs = [];
    for (int i = 0;
        i < interiore.gladiator.interiore.outputs.length;
        i++) {
      for (Propter propter
          in interiore.gladiator.interiore.outputs[i].rationibus) {
        if (propter.interiore.publicaClavis == publica) {
          bool primis = await Pera.isPrimis(publica, directory);
          PropterNotitia propterInfo = PropterNotitia(
              true,
              primis,
              interiore.indicatione,
              interiore.obstructionumNumerus,
              interiore.gladiator.interiore.outputs[i].defensio,
              interiore.gladiator.interiore.outputs[i].impetum);
          return Response.ok(json.encode({
            "data": propterInfo.toJson(),
            "scriptum": interiore.gladiator.toJson(),
            "gladiatorIdentitatis":
                interiore.gladiator.interiore.identitatis
          }));
        }
      }
    }
  }
  for (Propter propter in par!.rationibus) {
    if (propter.interiore.publicaClavis == publica) {
      PropterNotitia propterInfo =
          PropterNotitia(false, null, null, null, null, null);
      return Response.ok(json.encode({
        "data": propterInfo.toJson(),
        "scriptum": propter.toJson(),
        "gladiatorIdentiatis": null
      }));
    }
  }
  return Response.badRequest(
      body: json.encode({"code": 0, "message": "Propter not found"}));
}

Future<Response> propterNovus(Request req) async {
  ClavisPar kp = ClavisPar();
  return Response.ok(json.encode({
    "publicaClavis": kp.publicaClavis,
    "privatusClavis": kp.privatusClavis
  }));
}

Future<Response> propterStagnum(Request req) async {
  return Response.ok(json.encode(par!.rationibus.map((e) => e.toJson()).toList()));
}

Future<Response> propterHabetBid(Request req) async {
  final String publica = req.params['publica-clavis']!;
  Directory directorium =
      Directory('vincula/${argumentis!.obstructionumDirectorium}');
  List<Obstructionum> lo = await Obstructionum.getBlocks(directorium);
  final BigInt liber = await Pera.habetBid(true, publica, lo);
  final BigInt fixum = await Pera.habetBid(false, publica, lo);
  return Response.ok(json.encode({
    "liber": liber.toString(),
    "fixum": fixum.toString()
  }));
}

