export interface Clock {
  now(): Date;
}

export class FakeClock implements Clock {
  constructor(private currentTime: Date) {}

  now(): Date {
    return new Date(this.currentTime);
  }

  advance(durationMs: number): void {
    this.currentTime = new Date(this.currentTime.getTime() + durationMs);
  }
}

export function advanceToReminderWindow(
  clock: FakeClock,
  classStart: Date,
  reminderMinutes = 30,
): void {
  const reminderTime = new Date(
    classStart.getTime() - reminderMinutes * 60 * 1000,
  );
  clock.advance(reminderTime.getTime() - clock.now().getTime());
}
