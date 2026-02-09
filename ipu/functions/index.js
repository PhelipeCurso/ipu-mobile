const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notificarMudancaAgendamento =
functions.firestore
  .document("agendamentos/{agendamentoId}")
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();

      // Executa SOMENTE se status mudou
      if (before.status === after.status) return null;

      const membroId = after.idMembro;
      const agendamentoId = context.params.agendamentoId;

      const membroDoc = await admin.firestore()
        .collection("usuarios")
        .doc(membroId)
        .get();

      if (!membroDoc.exists) return null;

      const userData = membroDoc.data();

      // 🔥 suporte a múltiplos dispositivos
      let tokens = [];

      if (Array.isArray(userData.fcmTokens)) {
        tokens = userData.fcmTokens;
      } else if (userData.fcmToken) {
        tokens = [userData.fcmToken];
      }

      if (!tokens.length) return null;

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

      const message = {
        tokens: tokens,

        notification: {
          title: "Gabinete Pastoral",
          body: mensagem,
        },

        // 🔥 IMPORTANTE para Flutter navegar para tela específica
        data: {
          tipo: "agendamento",
          agendamentoId: agendamentoId,
          status: after.status,
        },

        android: {
          priority: "high",
        },

        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      console.log("Notificações enviadas:", response.successCount);

      // 🔥 remove tokens inválidos automaticamente
      const tokensInvalidos = [];

      response.responses.forEach((r, index) => {
        if (!r.success) {
          tokensInvalidos.push(tokens[index]);
        }
      });

      if (tokensInvalidos.length) {
        await admin.firestore()
          .collection("usuarios")
          .doc(membroId)
          .update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensInvalidos),
          });
      }

      return null;

    } catch (error) {
      console.error("Erro ao enviar notificação:", error);
      return null;
    }
  });
