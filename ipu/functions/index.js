const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notificarMudancaAgendamento =
functions.firestore
  .document("agendamentos/{agendamentoId}")
  .onUpdate(async (change, context) => {

    const before = change.before.data();
    const after = change.after.data();

    // Só executa se status mudou
    if (before.status === after.status) return null;

    const membroId = after.idMembro;

    const membroDoc = await admin.firestore()
      .collection("usuarios")
      .doc(membroId)
      .get();

    if (!membroDoc.exists) return null;

    const token = membroDoc.data().fcmToken;

    if (!token) return null;

    let mensagem = "";

    switch (after.status) {
      case "confirmado":
        mensagem = "Seu agendamento foi confirmado ✅";
        break;
      case "cancelado":
        mensagem = "Seu agendamento foi cancelado ❌";
        break;
      case "reagendado":
        mensagem = "Seu agendamento foi reagendado 📅";
        break;
      default:
        mensagem = "Atualização no seu agendamento";
    }

    const payload = {
      notification: {
        title: "Gabinete Pastoral",
        body: mensagem,
      },
      token: token,
    };

    return admin.messaging().send(payload);
});
