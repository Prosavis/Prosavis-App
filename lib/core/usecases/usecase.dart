import 'package:equatable/equatable.dart';

abstract class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
} 