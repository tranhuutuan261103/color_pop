import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/database_helper.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  void loadHomeData() async {
    emit(HomeLoading());
    try {
      final stats = await DatabaseHelper.instance.getStats();
      final inProgressCount = stats['in_progress'] ?? 0;
      final completedCount = stats['completed'] ?? 0;
      
      final user = await DatabaseHelper.instance.getUser();
      
      emit(HomeLoaded(
        userName: user.name,
        inProgressCount: inProgressCount,
        completedCount: completedCount,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}