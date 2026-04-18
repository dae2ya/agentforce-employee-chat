/**
 * ClosingTaskProgressController 테스트 클래스
 */
@IsTest
private class ClosingTaskProgressControllerTest {
    @IsTest
    static void getClosingProgress_returnsAllPhasesAndTasks() {
        Test.startTest();
        ClosingTaskProgressController.ClosingProgressResult result =
            ClosingTaskProgressController.getClosingProgress();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.phases, 'Phases should not be null');
        System.assertEquals(5, result.phases.size(), 'Should return 5 phases');

        for (ClosingTaskProgressController.PhaseWrapper phase : result.phases) {
            System.assertNotEquals(null, phase.id, 'Phase id should not be null');
            System.assertNotEquals(null, phase.label, 'Phase label should not be null');
            System.assertNotEquals(null, phase.tasks, 'Phase tasks should not be null');
            System.assertEquals(20, phase.tasks.size(), 'Each phase should have 20 tasks');
        }

        // Verify Phase 1 has expected error task
        ClosingTaskProgressController.PhaseWrapper phase1 = result.phases[0];
        ClosingTaskProgressController.TaskWrapper errorTask = null;
        for (ClosingTaskProgressController.TaskWrapper t : phase1.tasks) {
            if (t.status == 'error') {
                errorTask = t;
                break;
            }
        }
        System.assertNotEquals(null, errorTask, 'Phase 1 should have one error task');
        System.assertNotEquals(null, errorTask.errorMessage, 'Error task should have error message');
    }
}
