#include <iostream>
#include <iomanip>
#include <string>
#include <vector>

const int DAYS_IN_WEEK = 7;

struct Task {
    std::string description;
    std::string time;
};

struct DaySchedule {
    std::string dayName;
    std::vector<Task> tasks;
};

// Function to get the day name from the day number
std::string getDayName(int day) {
    const char* dayNames[] = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
    if (day >= 1 && day <= DAYS_IN_WEEK) {
        return dayNames[day - 1];
    } else {
        return "Invalid Day";
    }
}

// Function to display the menu
void displayMenu() {
    std::cout << "Weekly Planner Schedule Maker\n";
    std::cout << "1. Add Task\n";
    std::cout << "2. View Schedule\n";
    std::cout << "3. Exit\n";
}

int main() {
    DaySchedule schedule[DAYS_IN_WEEK];  // Array to store tasks for each day
    int choice;

    do {
        displayMenu();
        std::cout << "Enter your choice: ";
        std::cin >> choice;

        switch (choice) {
            case 1: {
                int day;
                std::cout << "Enter the day (1-7, 1=Monday, 7=Sunday): ";
                std::cin >> day;

                if (day >= 1 && day <= DAYS_IN_WEEK) {
                    Task newTask;
                    std::cout << "Enter the task for " << getDayName(day) << " (max 30 characters): ";
                    std::cin.ignore();  // Clear the newline character from the buffer
                    std::getline(std::cin, newTask.description);

                    std::cout << "Enter the time for the task (e.g., '10:00 AM'): ";
                    std::getline(std::cin, newTask.time);

                    schedule[day - 1].dayName = getDayName(day);
                    schedule[day - 1].tasks.push_back(newTask);

                    std::cout << "Task added successfully!\n";
                } else {
                    std::cout << "Invalid day. Please enter a day between 1 and 7.\n";
                }
                break;
            }
            case 2: {
                std::cout << "\nWeekly Schedule:\n";
                for (int i = 0; i < DAYS_IN_WEEK; ++i) {
                    if (!schedule[i].dayName.empty()) {
                        std::cout << std::setw(10) << "Day " << std::setw(2) << schedule[i].dayName << ":\n";
                        for (const Task &task : schedule[i].tasks) {
                            std::cout << std::setw(15) << "Task: " << std::setw(30) << task.description << " | ";
                            std::cout << std::setw(15) << "Time: " << task.time << "\n";
                        }
                        std::cout << "\n";
                    }
                }
                break;
            }
            case 3: {
                std::cout << "Exiting the program. Goodbye!\n";
                break;
            }
            default:
                std::cout << "Invalid choice. Please enter a valid option.\n";
        }

    } while (choice != 3);

    return 0;
}
