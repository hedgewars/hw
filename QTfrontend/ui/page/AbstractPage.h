/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * @file
 * @brief AbstractPage class definition
 */

#ifndef ABSTRACTPAGE_H
#define ABSTRACTPAGE_H

#include <QWidget>
#include <qpushbuttonwithsound.h>
#include <QFont>
#include <QGridLayout>
#include <QComboBox>
#include <QSignalMapper>

class QPushButtonWithSound;
class QGroupBox;
class QComboBox;
class QLabel;
class QToolBox;
class QLineEdit;
class QListWidget;
class QCheckBox;
class QSpinBox;
class QTextEdit;
class QRadioButton;
class QTableView;
class QTextBrowser;
class QTableWidget;
class QAction;
class QDataWidgetMapper;
class QAbstractItemModel;
class QSettings;
class QSlider;
class QGridlayout;

class AbstractPage : public QWidget
{
        Q_OBJECT

    public:

        /**
        * @brief Changes the desc text (should not be called manualy)
        *
        * @param desc the description of the widget focused
        */
        void setButtonDescription(QString desc);

        /**
        * @brief Changes the desc defaut text
        *
        * @param text the defaut desc
        */
        void setDefaultDescription(QString text);

        /**
        * @brief Get the desc defaut text
        */
        QString * getDefaultDescription();

    signals:

        /**
         * @brief This signal is emitted when going back to the previous is
         * requested - e.g. when the back-button is clicked.
         */
        void goBack();

        /**
         * @brief This signal is emitted when the page is displayed
         */
        void pageEnter();

        /**
         * @brief This signal is emitted when this page is left
         */
        void pageLeave();

    public slots:

        /**
         * @brief This slot is called to trigger this page's pageEnter signal
         */
        void triggerPageEnter();

        /**
         * @brief This slot is called to trigger this page's pageLeave signal
         */
        void triggerPageLeave();

    protected:
        /**
         * @brief Class constructor
         *
         * @param parent parent widget.
         */
        AbstractPage(QWidget * parent = 0);

        /// Class Destructor
        virtual ~AbstractPage() {};

        /// Call this in the constructor of your subclass.
        void initPage();

        /**
         * @brief Used during page construction.
         * You MUST implement this method in your subclass.
         *
         * Use it to define the main layout (no behavior) of the page.
         */
        virtual QLayout * bodyLayoutDefinition() = 0;

        /**
         * @brief Used during page construction.
         * You can implement this method in your subclass.
         *
         * Use it to define layout (not behavior) of the page's footer.
         */
        virtual QLayout * footerLayoutDefinition()
        {
            return NULL;
        };

        /**
         * @brief Used during page construction.
         * You can implement this method in your subclass.
         *
         * Use it to define layout (not behavior) of the page's footer to the left of the help text.
         */
        virtual QLayout * footerLayoutLeftDefinition()
        {
            return NULL;
        };

        /**
         * @brief Used during page construction.
         * You can implement this method in your subclass.
         *
         * This is a good place to connect signals within your page in order
         * to get the desired page behavior.<br />
         * Keep in mind not to expose twidgets as public!
         * instead define a signal with a meaningful name and connect the widget
         * signals to your page signals
         */
        virtual void connectSignals() {};

        /**
         * @brief Creates a default formatted button for this page.
         *
         * @param name name of the button - used as its text if not hasIcon.
         * @param hasIcon set to true if this is a picture button.
         *
         * @return the button.
         */
        QPushButtonWithSound * formattedButton(const QString & name, bool hasIcon = false);
        QPushButton * formattedSoundlessButton(const QString & name, bool hasIcon = false);

        /**
         * @brief Creates a default formatted button and adds it to a
         * grid layout at the location specified.
         *
         * @param name label or path to icon of the button (depends on hasIcon)
         * @param grid pointer of the grid layout in which to insert the button.
         * @param row layout row index in which to insert the button.
         * @param column layout column index in which to insert the button.
         * @param rowSpan how many layout rows the button will span.
         * @param columnSpan how many layout columns the button will span.
         * @param hasIcon set to true if this is a picture button.
         * @param alignment alignment of the button in the layout.
         *
         * @return the button.
         */
        QPushButtonWithSound * addButton(const QString & name, QGridLayout * grid, int row, int column, int rowSpan = 1, int columnSpan = 1, bool hasIcon = false, Qt::Alignment alignment = 0);
        QPushButton * addSoundlessButton(const QString & name, QGridLayout * grid, int row, int column, int rowSpan = 1, int columnSpan = 1, bool hasIcon = false, Qt::Alignment alignment = 0);

        /**
         * @brief Creates a default formatted button and adds it to a
         * grid layout at the location specified.
         *
         * @param name label or path to icon of the button (depends on hasIcon)
         * @param box pointer of the box layout in which to insert the button.
         * @param where layout ndex in which to insert the button.
         * @param hasIcon set to true if this is a picture button.
         * @param alignment alignment of the button in the layout.
         *
         * @return the button.
         */
        QPushButtonWithSound * addButton(const QString & name, QBoxLayout * box, int where, bool hasIcon = false, Qt::Alignment alignment = 0);
        QPushButton* addSoundlessButton(const QString & name, QBoxLayout * box, int where, bool hasIcon = false, Qt::Alignment alignment = 0);

        /**
         * @brief Changes visibility of the back-button.
         *
         * @param visible set to true if the button should be visible.
         */
        void setBackButtonVisible(bool visible = true);

        QFont * font14; ///< used font

        QLabel * descLabel; ///< text description
        QString * defautDesc;

        QPushButtonWithSound * btnBack; ///< back button
};

#endif

