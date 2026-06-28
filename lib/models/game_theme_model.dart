import 'package:flutter/material.dart';

enum BlockSpriteStyle { classic, wood, space }

class GameThemeModel {
  const GameThemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.backgroundGradient,
    required this.glowColorA,
    required this.glowColorB,
    required this.tileOverlayColor,
    required this.bottomBlocksColor,
    required this.panelColor,
    required this.panelBorderColor,
    required this.boardBorderColor,
    required this.boardFrameShadowColor,
    required this.boardFillColor,
    required this.boardEmptyCellColor,
    required this.boardGridLineColor,
    required this.validPreviewColor,
    required this.invalidPreviewColor,
    required this.ghostColor,
    required this.selectedBlockBorderColor,
    required this.blockContainerColor,
    required this.specialBombColor,
    required this.specialIceColor,
    required this.specialMagnetColor,
    required this.blockSpriteStyle,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final List<Color> backgroundGradient;
  final Color glowColorA;
  final Color glowColorB;
  final Color tileOverlayColor;
  final Color bottomBlocksColor;
  final Color panelColor;
  final Color panelBorderColor;
  final Color boardBorderColor;
  final Color boardFrameShadowColor;
  final Color boardFillColor;
  final Color boardEmptyCellColor;
  final Color boardGridLineColor;
  final Color validPreviewColor;
  final Color invalidPreviewColor;
  final Color ghostColor;
  final Color selectedBlockBorderColor;
  final Color blockContainerColor;
  final Color specialBombColor;
  final Color specialIceColor;
  final Color specialMagnetColor;
  final BlockSpriteStyle blockSpriteStyle;
}

class GameThemeCatalog {
  GameThemeCatalog._();

  static const GameThemeModel classic = GameThemeModel(
    id: 'classic',
    name: 'Classic Neon',
    description: 'Original electric puzzle look.',
    price: 0,
    backgroundGradient: [
      Color(0xFF133E8E),
      Color(0xFF0C2B62),
      Color(0xFF091B3E),
    ],
    glowColorA: Color(0x5538E8FF),
    glowColorB: Color(0x55A54DFF),
    tileOverlayColor: Color(0x14000000),
    bottomBlocksColor: Color(0x88338CFF),
    panelColor: Color(0xAA081A3F),
    panelBorderColor: Color(0x5538A6FF),
    boardBorderColor: Color(0xFF1EB8FF),
    boardFrameShadowColor: Color(0x881EB8FF),
    boardFillColor: Color(0xFF041A44),
    boardEmptyCellColor: Color(0xFF082C5A),
    boardGridLineColor: Color(0x553FA3F7),
    validPreviewColor: Color(0xFFCFE2FF),
    invalidPreviewColor: Color(0xFFFFCDD2),
    ghostColor: Color(0x553FA3F7),
    selectedBlockBorderColor: Color(0xFFFFD54F),
    blockContainerColor: Color(0xAA0A2A63),
    specialBombColor: Color(0xFFE53935),
    specialIceColor: Color(0xFF49CFFF),
    specialMagnetColor: Color(0xFFFFC107),
    blockSpriteStyle: BlockSpriteStyle.classic,
  );

  static const GameThemeModel wooden = GameThemeModel(
    id: 'wooden',
    name: 'Woodland Craft',
    description: 'Warm wooden board and carved blocks.',
    price: 220,
    backgroundGradient: [
      Color(0xFF5A3A1E),
      Color(0xFF3F2815),
      Color(0xFF2B1B10),
    ],
    glowColorA: Color(0x559B6A3F),
    glowColorB: Color(0x557A5A3A),
    tileOverlayColor: Color(0x1A2A1A10),
    bottomBlocksColor: Color(0xA06E4A2D),
    panelColor: Color(0xCC3D2A1B),
    panelBorderColor: Color(0xAAAD7A48),
    boardBorderColor: Color(0xFFD7A86A),
    boardFrameShadowColor: Color(0x88552F14),
    boardFillColor: Color(0xFF3B2817),
    boardEmptyCellColor: Color(0xFF4D331D),
    boardGridLineColor: Color(0x886A4929),
    validPreviewColor: Color(0xFFDCC5A5),
    invalidPreviewColor: Color(0xFFECAEA6),
    ghostColor: Color(0x667F5D3F),
    selectedBlockBorderColor: Color(0xFFFFE0B2),
    blockContainerColor: Color(0xCC4A2F1D),
    specialBombColor: Color(0xFFD75A4A),
    specialIceColor: Color(0xFF8AD0E6),
    specialMagnetColor: Color(0xFFF2C66A),
    blockSpriteStyle: BlockSpriteStyle.wood,
  );

  static const GameThemeModel space = GameThemeModel(
    id: 'space',
    name: 'Deep Space',
    description: 'Futuristic cosmic glow and neon cubes.',
    price: 360,
    backgroundGradient: [
      Color(0xFF11083B),
      Color(0xFF130F52),
      Color(0xFF060720),
    ],
    glowColorA: Color(0x558E6BFF),
    glowColorB: Color(0x5538D7FF),
    tileOverlayColor: Color(0x120F102A),
    bottomBlocksColor: Color(0x88364CFF),
    panelColor: Color(0xAA10184A),
    panelBorderColor: Color(0x887A8FFF),
    boardBorderColor: Color(0xFF8A7BFF),
    boardFrameShadowColor: Color(0x887A8FFF),
    boardFillColor: Color(0xFF0A1041),
    boardEmptyCellColor: Color(0xFF141A5C),
    boardGridLineColor: Color(0x667084FF),
    validPreviewColor: Color(0xFFCAD4FF),
    invalidPreviewColor: Color(0xFFFFB8D4),
    ghostColor: Color(0x556A72FF),
    selectedBlockBorderColor: Color(0xFF9DF8FF),
    blockContainerColor: Color(0xAA111A57),
    specialBombColor: Color(0xFFFF5A8A),
    specialIceColor: Color(0xFF5BE5FF),
    specialMagnetColor: Color(0xFFFFE75D),
    blockSpriteStyle: BlockSpriteStyle.space,
  );

  static const List<GameThemeModel> allThemes = [classic, wooden, space];

  static GameThemeModel byId(String id) {
    return allThemes.firstWhere(
      (GameThemeModel theme) => theme.id == id,
      orElse: () => classic,
    );
  }
}
