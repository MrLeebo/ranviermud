var uuid = require('node-uuid');
var util = require('util');
var Npc = require('../../src/npcs').Npc;
var Events = require('../../src/events').Events;

exports.listeners = {
  playerEnter: function (l10n) {
    return function (player, players) {
      player.sayL10n(l10n, 'CONSOLE');
    }
  },

  playerLeave: function (l10n) {
    return function (player, players) {
      players.broadcastAtL10n(player, l10n, 'SPAWN', player.getName());

      var alienTemplate = Events.getNpcs().getByVnum(1)[0];
      var npc = new Npc(alienTemplate);
      var room = Events.getRooms().getAt(1);
      npc.setRoom(room);
      Events.getNpcs().add(npc);
      room.addNpc(npc.getUuid());
      util.log("\t\tLoaded npc [uuid:" + npc.getUuid() + ', vnum:' + npc.vnum + ']');
    }
  }
};
