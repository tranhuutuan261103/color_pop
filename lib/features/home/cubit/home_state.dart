abstract class HomeState {}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userName;
  final int inProgressCount;
  final int completedCount;
  
  HomeLoaded({
    required this.userName,
    required this.inProgressCount,
    required this.completedCount,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}