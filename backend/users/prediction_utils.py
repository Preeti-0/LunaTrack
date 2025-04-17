from datetime import datetime, timedelta

def predict_cycle_dates(latest_period_date, cycle_length=28, period_duration=5):
    """
    Based on the latest period log, predict next period days,
    ovulation day, and fertile window.
    """

    # Ensure date is in datetime format
    if isinstance(latest_period_date, str):
        latest_period_date = datetime.strptime(latest_period_date, "%Y-%m-%d").date()

    # Predicted next period start
    next_period_start = latest_period_date + timedelta(days=cycle_length)
    next_period_days = [(next_period_start + timedelta(days=i)).isoformat() for i in range(period_duration)]

    # Ovulation: 14 days before next period
    ovulation_day = next_period_start - timedelta(days=14)
    ovulation_day_str = ovulation_day.isoformat()

    # Fertile window: 5 days before ovulation to 1 day after
    fertile_start = ovulation_day - timedelta(days=5)
    fertile_end = ovulation_day + timedelta(days=1)
    fertile_window = [(fertile_start + timedelta(days=i)).isoformat() for i in range((fertile_end - fertile_start).days + 1)]

    return {
        "next_period_days": next_period_days,
        "ovulation_day": ovulation_day_str,
        "fertile_window": fertile_window
    }
