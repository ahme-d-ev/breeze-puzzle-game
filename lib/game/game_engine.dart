import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/board_cell_model.dart';
import '../models/block_model.dart';

class BlockPlacement {
  const BlockPlacement({required this.row, required this.column});

  final int row;
  final int column;
}

class GameEngine extends ChangeNotifier {
  GameEngine({this.boardSize = 8})
    : board = List<List<BoardCellModel?>>.generate(
        boardSize,
        (_) => List<BoardCellModel?>.filled(boardSize, null),
      );

  final int boardSize;
  final List<List<BoardCellModel?>> board;
  final Set<int> _clearingCells = <int>{};
  final Set<int> _placingCells = <int>{};

  int score = 0;
  int _lastClearedLineCount = 0;
  int _totalClearedLines = 0;
  int _lastDestroyedIceBlocks = 0;
  int _totalDestroyedIceBlocks = 0;
  int? _lastComboAnchorRow;
  int? _lastComboAnchorColumn;
  bool isRunning = false;
  bool _isClearing = false;

  int get lastClearedLineCount => _lastClearedLineCount;

  int get totalClearedLines => _totalClearedLines;

  int get lastDestroyedIceBlocks => _lastDestroyedIceBlocks;

  int get totalDestroyedIceBlocks => _totalDestroyedIceBlocks;

  int? get lastComboAnchorRow => _lastComboAnchorRow;

  int? get lastComboAnchorColumn => _lastComboAnchorColumn;

  bool isCellClearing(int row, int column) {
    return _clearingCells.contains(_cellIndex(row, column));
  }

  bool isCellPlacing(int row, int column) {
    return _placingCells.contains(_cellIndex(row, column));
  }

  void startGame() {
    score = 0;
    _lastClearedLineCount = 0;
    _lastDestroyedIceBlocks = 0;
    _totalClearedLines = 0;
    _totalDestroyedIceBlocks = 0;
    _lastComboAnchorRow = null;
    _lastComboAnchorColumn = null;
    isRunning = true;
    clearBoard();
    notifyListeners();
  }

  void endGame() {
    isRunning = false;
    notifyListeners();
  }

  void resetGame() {
    score = 0;
    _lastClearedLineCount = 0;
    _lastDestroyedIceBlocks = 0;
    _totalClearedLines = 0;
    _totalDestroyedIceBlocks = 0;
    _lastComboAnchorRow = null;
    _lastComboAnchorColumn = null;
    isRunning = false;
    clearBoard();
    notifyListeners();
  }

  bool isCellFilled(int row, int column) {
    return board[row][column] != null;
  }

  Color? getCellColor(int row, int column) {
    return board[row][column]?.color;
  }

  SpecialBlockType getCellSpecialType(int row, int column) {
    return board[row][column]?.specialType ?? SpecialBlockType.none;
  }

  int getCellBombCountdown(int row, int column) {
    return board[row][column]?.bombCountdown ?? 0;
  }

  int getCellIceHitsRemaining(int row, int column) {
    return board[row][column]?.iceHitsRemaining ?? 0;
  }

  bool placeBlock(int row, int column) {
    if (!isRunning || _isClearing) {
      return false;
    }
    if (row < 0 || row >= boardSize || column < 0 || column >= boardSize) {
      return false;
    }
    if (board[row][column] != null) {
      return false;
    }

    board[row][column] = const BoardCellModel(color: Color(0xFF4FC3F7));
    _resolveBoardAfterPlacement();
    notifyListeners();
    return true;
  }

  bool canPlaceBlockShape(BlockModel block, int startRow, int startColumn) {
    if (!isRunning || _isClearing) {
      return false;
    }

    for (int row = 0; row < block.cells.length; row++) {
      for (int column = 0; column < block.cells[row].length; column++) {
        if (block.cells[row][column] == 0) {
          continue;
        }

        final int boardRow = startRow + row;
        final int boardColumn = startColumn + column;

        if (boardRow < 0 ||
            boardRow >= boardSize ||
            boardColumn < 0 ||
            boardColumn >= boardSize) {
          return false;
        }

        if (board[boardRow][boardColumn] != null) {
          return false;
        }
      }
    }

    return true;
  }

  bool placeBlockShape(BlockModel block, int startRow, int startColumn) {
    if (!isRunning || !canPlaceBlockShape(block, startRow, startColumn)) {
      return false;
    }

    final Set<int> placedCells = <int>{};
    for (int row = 0; row < block.cells.length; row++) {
      for (int column = 0; column < block.cells[row].length; column++) {
        if (block.cells[row][column] == 1) {
          board[startRow + row][startColumn + column] = BoardCellModel(
            color: block.color,
            specialType: block.specialType,
            bombCountdown: block.bombCountdown,
            iceHitsRemaining: block.iceDurability,
          );
          placedCells.add(_cellIndex(startRow + row, startColumn + column));
        }
      }
    }

    _placingCells
      ..clear()
      ..addAll(placedCells);
    unawaited(_clearPlacementAnimation());

    _resolveBoardAfterPlacement();
    notifyListeners();
    return true;
  }

  bool canPlaceBlockAnywhere(BlockModel block) {
    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        if (canPlaceBlockShape(block, row, column)) {
          return true;
        }
      }
    }
    return false;
  }

  BlockPlacement? findNearestValidPlacement(
    BlockModel block,
    int targetRow,
    int targetColumn,
  ) {
    BlockPlacement? best;
    int bestDistance = 1 << 30;

    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        if (!canPlaceBlockShape(block, row, column)) {
          continue;
        }

        final int distance =
            (targetRow - row).abs() + (targetColumn - column).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          best = BlockPlacement(row: row, column: column);
        }
      }
    }

    return best;
  }

  BlockPlacement? findGhostPlacement(BlockModel block, int preferredColumn) {
    final int maxColumn = boardSize - block.cells.first.length;
    final int column = preferredColumn.clamp(0, maxColumn);

    for (int row = boardSize - block.cells.length; row >= 0; row--) {
      if (canPlaceBlockShape(block, row, column)) {
        return BlockPlacement(row: row, column: column);
      }
    }

    return null;
  }

  bool hasAnyValidMove(List<BlockModel> blocks) {
    if (!isRunning) {
      return false;
    }

    if (_isClearing) {
      return true;
    }

    for (final BlockModel block in blocks) {
      if (canPlaceBlockAnywhere(block)) {
        return true;
      }
    }

    return false;
  }

  void clearBoard() {
    _isClearing = false;
    _clearingCells.clear();
    _placingCells.clear();
    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        board[row][column] = null;
      }
    }
  }

  Future<void> _clearPlacementAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _placingCells.clear();
    notifyListeners();
  }

  void _resolveBoardAfterPlacement() {
    _decrementBombCountdowns();
    _clearCompletedLinesAfterBombTick();
  }

  void _clearCompletedLinesAfterBombTick() {
    final Set<int> completedRows = <int>{};
    final Set<int> completedColumns = <int>{};

    for (int row = 0; row < boardSize; row++) {
      if (board[row].every((BoardCellModel? filled) => filled != null)) {
        completedRows.add(row);
      }
    }

    for (int column = 0; column < boardSize; column++) {
      bool fullColumn = true;
      for (int row = 0; row < boardSize; row++) {
        if (board[row][column] == null) {
          fullColumn = false;
          break;
        }
      }
      if (fullColumn) {
        completedColumns.add(column);
      }
    }

    if (completedRows.isEmpty && completedColumns.isEmpty) {
      _lastClearedLineCount = 0;
      _lastDestroyedIceBlocks = 0;
      _lastComboAnchorRow = null;
      _lastComboAnchorColumn = null;
      if (_hasExpiredBombOutsideClearedLines(<int>{}, <int>{})) {
        endGame();
      }
      return;
    }

    if (_hasExpiredBombOutsideClearedLines(completedRows, completedColumns)) {
      endGame();
      return;
    }

    _lastComboAnchorRow = _computeComboAnchorRow(completedRows);
    _lastComboAnchorColumn = _computeComboAnchorColumn(completedColumns);
    _lastClearedLineCount = completedRows.length + completedColumns.length;
    _totalClearedLines += _lastClearedLineCount;
    score += _lastClearedLineCount * 100;
    _isClearing = true;

    for (final int row in completedRows) {
      for (int column = 0; column < boardSize; column++) {
        _clearingCells.add(_cellIndex(row, column));
      }
    }

    for (final int column in completedColumns) {
      for (int row = 0; row < boardSize; row++) {
        _clearingCells.add(_cellIndex(row, column));
      }
    }

    notifyListeners();
    unawaited(_clearLinesWithAnimation(completedRows, completedColumns));
  }

  void _decrementBombCountdowns() {
    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        final BoardCellModel? cell = board[row][column];
        if (cell == null || !cell.isBomb) {
          continue;
        }
        board[row][column] = cell.tickBomb();
      }
    }
  }

  bool _hasExpiredBombOutsideClearedLines(
    Set<int> completedRows,
    Set<int> completedColumns,
  ) {
    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        final BoardCellModel? cell = board[row][column];
        if (cell == null || !cell.isBomb || cell.bombCountdown > 0) {
          continue;
        }

        final bool cellIsOnClearedLine =
            completedRows.contains(row) || completedColumns.contains(column);
        if (!cellIsOnClearedLine) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _clearLinesWithAnimation(
    Set<int> completedRows,
    Set<int> completedColumns,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));

    final Set<Color> magnetColors = <Color>{};
    final Set<int> processedCells = <int>{};
    int destroyedIceBlocks = 0;

    for (final int row in completedRows) {
      for (int column = 0; column < boardSize; column++) {
        destroyedIceBlocks += await _clearCellIfNeeded(
          row,
          column,
          processedCells,
          magnetColors,
        );
      }
    }

    for (final int column in completedColumns) {
      for (int row = 0; row < boardSize; row++) {
        destroyedIceBlocks += await _clearCellIfNeeded(
          row,
          column,
          processedCells,
          magnetColors,
        );
      }
    }

    _lastDestroyedIceBlocks = destroyedIceBlocks;
    _totalDestroyedIceBlocks += destroyedIceBlocks;

    if (magnetColors.isNotEmpty) {
      _applyMagnetExplosion(magnetColors);
    }

    _clearingCells.clear();
    _placingCells.clear();
    _isClearing = false;
    notifyListeners();

    if (_hasAnyCompletedLine()) {
      _clearCompletedLinesAfterBombTick();
    }
  }

  Future<int> _clearCellIfNeeded(
    int row,
    int column,
    Set<int> processedCells,
    Set<Color> magnetColors,
  ) async {
    final int cellIndex = _cellIndex(row, column);
    if (!processedCells.add(cellIndex)) {
      return 0;
    }

    final BoardCellModel? cell = board[row][column];
    if (cell == null) {
      return 0;
    }

    if (cell.isIce && cell.iceHitsRemaining > 1) {
      board[row][column] = cell.weakenIce();
      return 0;
    }

    if (cell.isMagnet) {
      magnetColors.add(cell.color);
    }

    board[row][column] = null;
    return cell.isIce ? 1 : 0;
  }

  void _applyMagnetExplosion(Set<Color> magnetColors) {
    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        final BoardCellModel? cell = board[row][column];
        if (cell == null || !magnetColors.contains(cell.color)) {
          continue;
        }
        board[row][column] = null;
      }
    }
  }

  bool _hasAnyCompletedLine() {
    for (int row = 0; row < boardSize; row++) {
      if (board[row].every((BoardCellModel? cell) => cell != null)) {
        return true;
      }
    }

    for (int column = 0; column < boardSize; column++) {
      bool fullColumn = true;
      for (int row = 0; row < boardSize; row++) {
        if (board[row][column] == null) {
          fullColumn = false;
          break;
        }
      }
      if (fullColumn) {
        return true;
      }
    }

    return false;
  }

  int _computeComboAnchorRow(Set<int> completedRows) {
    if (completedRows.isEmpty) {
      return boardSize ~/ 2;
    }

    final int total = completedRows.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    return (total / completedRows.length).round();
  }

  int _computeComboAnchorColumn(Set<int> completedColumns) {
    if (completedColumns.isEmpty) {
      return boardSize ~/ 2;
    }

    final int total = completedColumns.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    return (total / completedColumns.length).round();
  }

  int _cellIndex(int row, int column) {
    return row * boardSize + column;
  }
}
