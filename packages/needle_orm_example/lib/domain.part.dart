part of 'domain.dart';

// can write business logic here.

extension BizUser on User {
  static final Logger _logger = Logger('USER');
  bool isAdmin() {
    return name!.startsWith('admin');
  }

  void beforeInsert() {
    logger.info('');
    _logger.info('beforeInsert ....');
  }

  void afterInsert() {
    _logger.info('afterInsert ....');
  }

  void beforeRemove() {
    _logger.info('beforeRemove ....');
  }

  void beforeRemovePermanent() {
    _logger.info('beforeRemovePermanent ....');
  }

  void beforeUpdate() {
    _logger.info('beforeUpdate ....');
  }

  void afterLoad() {
    _logger.info('afterLoad ....');
  }

  void afterUpdate() {
    _logger.info('afterUpdate ....');
  }

  void afterRemove() {
    _logger.info('afterRemove ....');
  }

  void afterRemovePermanent() {
    _logger.info('afterRemovePermanent ....');
  }
}
