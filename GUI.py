import PySimpleGUI as sg
import SQL as Queries

Tables = Queries.Tables()
table = 0
text = 'Choose  to change'
id_prime_column = 0

def make_window_menu():
    layout = [[sg.Text('Tables')],
            [[sg.Button(f'{Tables[i]}', size= (12, 3)) for i in range(len(Tables))]],
            [sg.Text('Queries')],
            [sg.Button('count group on course', key = '-BUT1-', button_color = ('black','yellow'),  size= (12, 3)), 
             sg.Button('count student on course', key = '-BUT2-', button_color = ('black','yellow'),  size= (12, 3)),
             sg.Button('number students at teacher', key = '-BUT3-', button_color = ('black','yellow'),  size= (12, 3)),
             sg.Button('extendend timetable for group 101', key = '-BUT4-', button_color = ('black','yellow'),  size= (12, 3)),
             ],
            [sg.Text()],
            [sg.Button('Exit', button_color= ('black','red'), size= (12, 3) )]]
    return sg.Window('Menu', layout, finalize=True, size= (950, 300),  element_justification='c')

def make_window_table(event):
    table = event
    headings = Queries.Column_Headers(table)
    data = Queries.Table_Data(table)
    primarykey = Queries.Find_primary_key(table)
    if primarykey != []:
        change = sg.Button('Change')
        delete = sg.Button('Delete')
    else:
        delete = sg.Text('')
        change = sg.Text('')

    layout = [[sg.Table(data, headings=headings, enable_events=True, justification='left', key='-TABLE-')],
        [sg.Button('< Prev'), sg.Button('Add'),  sg.Button('Find'), delete, change]]
    return sg.Window('Table', layout, finalize=True)


def make_window_add(table):
    headings = list(Queries.Column_Headers(table))
    layout = [[[sg.Text(heading), sg.InputText(key=heading, do_not_clear=False)] for heading in headings],
    [sg.Button('< Prev'), sg.Button('Write'), sg.Button('Exit')]]
    return sg.Window('Add', layout, finalize=True)

def make_window_find(table):
    headings = list(Queries.Column_Headers(table))
    layout = [[sg.Text('Select a search option')],
               [sg.Listbox(values=headings, select_mode=sg.LISTBOX_SELECT_MODE_EXTENDED,
                    enable_events=True, key="-LISTBOX-")],
                [sg.InputText( key='-INPUT-', do_not_clear=False)],
                [sg.Button('< Prev'), sg.Button('OK')]]
    return sg.Window('Find', layout, finalize=True)

def make_window_table_find(table, values):
    headings = Queries.Column_Headers(table)
    data = Queries.Find(table, values)
    layout = [[sg.Table(data, headings=headings, justification='left', key='-TABLE-')],
        [sg.Button('< Prev')]]
    return sg.Window('Table', layout, finalize=True)

def make_window_change(table, values, data_selected):
    global id_prime_column
    headings = list(Queries.Column_Headers(table))
    data_selected = data_selected[0]
    primarykey = Queries.Find_primary_key(table)
    for (i, item) in enumerate(headings, start=1):
        if item == primarykey:
            #print(item)
            column_select = i
            break
    headings.remove(primarykey)

    id_prime_column = data_selected[column_select-1]
    layout = [[sg.Text(primarykey), sg.Text(data_selected[column_select-1])],
              [sg.Combo(values=headings, enable_events=True, key="-COMBO-")],
              [sg.Text('change:'), sg.Text(text, key='-TEXT-')],
        [ sg.InputText(key='-INPUT-', do_not_clear=False)],
    [sg.Button('< Prev'), sg.Button('Write'), sg.Button('Exit')]]

    return sg.Window('Change', layout, finalize=True)

def make_window_count_group_on_course():
    headings = ['course name', 'number of groups in the course']
    data = Queries.count_group_on_course()
    layout = [[sg.Table(data, headings=headings, enable_events=True, justification='left', key='-TABLE-')],
        [sg.Button('< Prev')]]
    return sg.Window('Table', layout, finalize=True)

def make_window_students_on_course():
    headings = ['course name', 'students_on_course', 'total cost']
    data = Queries.students_on_course()
    layout = [[sg.Table(data, headings=headings, enable_events=True, justification='left', key='-TABLE-')],
        [sg.Button('< Prev')]]
    return sg.Window('Table', layout, finalize=True)

def make_window_number_students_at_teacher():
    headings = ['teacher', 'number_students']
    data = Queries.number_students_at_teacher()
    layout = [[sg.Table(data, headings=headings, enable_events=True, justification='left', key='-TABLE-')],
        [sg.Button('< Prev')]]
    return sg.Window('Table', layout, finalize=True)

def make_window_extented_timetable():
    headings = ['number_group','teacher', 'number_week',  'name_day', 'number_pairs', 'start_pairs', 'end_pairs']
    data = Queries.extended_timetable()
    layout = [[sg.Table(data, headings=headings, enable_events=True, justification='left', key='-TABLE-')],
        [sg.Button('< Prev')]]
    return sg.Window('Table', layout, finalize=True)

def make_window():
    sg.theme('DarkAmber')
    window_menu, window_table, window_add, window_find, window_table_find, window_change, window_queries = make_window_menu(), None, None, None, None, None, None

    while True:
        window, event, values = sg.read_all_windows()

        if window == window_menu and event in (sg.WIN_CLOSED, 'Exit'):
            break

        if window == window_menu:
            if event in Tables:
                table = event
                window_menu.hide()
                window_table = make_window_table(event)
            elif event == '-BUT1-':
                window_menu.hide()
                window_queries = make_window_count_group_on_course()
            elif event == '-BUT2-':
                window_menu.hide()
                window_queries = make_window_students_on_course() 
            elif event == '-BUT3-':
                window_menu.hide()
                window_queries = make_window_number_students_at_teacher() 
            elif event == '-BUT4-':
                window_menu.hide()
                window_queries = make_window_extented_timetable() 

        if window == window_queries:
            if event in (sg.WIN_CLOSED, '< Prev'):
                window_queries.close()
                window_menu.un_hide()

        if window == window_table:
            if event == '-TABLE-':
                data_selected = [Queries.Table_Data(table)[row] for row in values[event]]

            if event in (sg.WIN_CLOSED, '< Prev'):
                window_table.close()
                window_menu.un_hide()
            elif event == 'Add':
                window_table.close()
                window_add = make_window_add(table)
            elif event == 'Find':
                window_table.close()
                window_find = make_window_find(table)
            elif event == 'Delete':
                headings = list(Queries.Column_Headers(table))
                data_selected = data_selected[0]
                primarykey = Queries.Find_primary_key(table)
                for (i, item) in enumerate(headings, start=1):
                    if item == primarykey:
                        column_select = i - 1
                        break
                Queries.Delete(table, data_selected[0])
                data = Queries.Table_Data(table)
                window['-TABLE-'].update(data)

            elif event == 'Change':
                try:
                    if data_selected != 0:
                        window_table.close()
                        window_change = make_window_change(table, values, data_selected)
                except BaseException:
                    sg.popup_error("Select the line to change")
        
        if window == window_add:
            if event in (sg.WIN_CLOSED, '< Prev'):
                window_add.close()
                window_table = make_window_table(table)
            if event == 'Write':
                if (Queries.Add(table, values)) == "error":
                    sg.popup_error("The data entered is incorrect, please try again")
                else:
                    window_add.close()
                    window_table = make_window_table(table)

        if window == window_find:
            print(values['-LISTBOX-'])
            if event in (sg.WIN_CLOSED, '< Prev'):
                window_find.close()
                window_table = make_window_table(table)
            if event == 'OK':
                    window_find.close()
                    window_table_find = make_window_table_find(table, values)

        if window == window_table_find:
            if event in (sg.WIN_CLOSED, '< Prev'):
                window_table_find.close()
                window_table = make_window_table(table)         

        if window == window_change:
            if event in (sg.WIN_CLOSED, '< Prev'):
                text = 'Choose  to change'
                window_change.close()
                window_table = make_window_table(table)
                data_selected = 0
            elif event == '-COMBO-':
                headings = list(Queries.Column_Headers(table))
                header = values['-COMBO-']
                for (i, item) in enumerate(headings, start=1):
                    if item == header:
                        column_select = i
                text = data_selected[0][column_select-1]
                window['-TEXT-'].update(text)
            elif event == 'Write':
                print("values = ", values)
                if (Queries.Change(table, values, id_prime_column)) == "error":
                    sg.popup_error("The data entered is incorrect, please try again")  
                else:
                    sg.popup_ok("Data changed successfully")
                    window_change.close()
                    window_table = make_window_table(table) 

    window.close()