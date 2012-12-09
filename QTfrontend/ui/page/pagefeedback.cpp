/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include <QHBoxLayout>
#include <QLineEdit>
#include <QTextBrowser>
#include <QLabel>
#include <QHttp>
#include <QSysInfo>
#include <QDebug>
#include <QBuffer>
#include <QApplication>
#include <QDesktopWidget>
#include <QNetworkReply>
#include <QProcess>
#include <QMessageBox>

#include <string>

#ifdef Q_WS_WIN
#define WINVER 0x0500
#include <windows.h>
#else
#include <unistd.h>
#include <sys/types.h>
#endif

#ifdef Q_WS_MAC
#include <sys/sysctl.h>
#endif

#include <stdint.h>

#include "pagefeedback.h"
#include "hwconsts.h"

QLayout * PageFeedback::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();
    QHBoxLayout * summaryLayout = new QHBoxLayout();
    QHBoxLayout * emailLayout = new QHBoxLayout();
    QHBoxLayout * combinedTopLayout = new QHBoxLayout();

    info = new QLabel();
    info->setText(
        "<style type=\"text/css\">"
        "a { color: #fc0; }"
        "b { color: #0df; }"
        "</style>"
        "<div align=\"center\"><h1>Please give us a feedback!</h1>"
        "<h3>We are always happy about suggestions, ideas or bug reports.<h3>"
        "<h4>The feedback will be posted as a new issue on our Google Code page.<br />"
        "<b>Don't forget to mention your email or you won't be able to receive updates on this topic!</b><br /></h4>"
        //"<h4>Your email is optional, but if given, you will be notified of responses.<h4>"
        "</div>"
    );
    pageLayout->addWidget(info);

    label_summary = new QLabel();
    label_summary->setText(QLabel::tr("Summary"));
    summaryLayout->addWidget(label_summary);
    summary = new QLineEdit();
    summaryLayout->addWidget(summary);
    combinedTopLayout->addLayout(summaryLayout);

    label_email = new QLabel();
    label_email->setText(QLabel::tr("Your Email"));
    emailLayout->addWidget(label_email);
    email = new QLineEdit();
    emailLayout->addWidget(email);
    
    //  Email -- although implemented -- doesn't seem to work as intended.
    //  It's sent in the XML as a <issues:cc> , the <entry>, but it doesn't seem
    //  to actually do anything. If you figure out how to fix that, uncomment these lines
    //  and the line above in the 'info' QLabel to re-enable this feature.
    //  UPDATE: I found out that CC only works if that email is a member of the
    //  Google Code project. So this feature is pretty much useless atm.
    /*
    combinedTopLayout->addLayout(emailLayout);
    combinedTopLayout->insertSpacing(1, 50);
    */

    pageLayout->addLayout(combinedTopLayout);

    label_description = new QLabel();
    label_description->setText(QLabel::tr("Description"));
    pageLayout->addWidget(label_description, 0, Qt::AlignHCenter);
    description = new QTextBrowser();

    EmbedSystemInfo();
    
    description->setReadOnly(false);
    pageLayout->addWidget(description);

    return pageLayout;
}

void PageFeedback::EmbedSystemInfo()
{
    // Gather some information about the system and embed it into the report
    QDesktopWidget* screen = QApplication::desktop();
    QString os_version = "Operating system: ";
    QString qt_version = QString("Qt version: ") + QT_VERSION_STR + QString("\n");
    QString total_ram = "Total RAM: ";
    QString number_of_cores = "Number of cores: ";
    QString compiler_bits = "Compiler architecture: ";
    QString compiler_version = "Compiler version: ";
    QString kernel_line = "Kernel: ";
    QString screen_size = "Size of the screen(s): " +
        QString::number(screen->width()) + "x" + QString::number(screen->height()) + "\n";
    QString number_of_screens = "Number of screens: " + QString::number(screen->screenCount()) + "\n";
    std::string processor_name = "Processor: ";

    // platform specific code
#ifdef Q_WS_MACX
    number_of_cores += QString::number(sysconf(_SC_NPROCESSORS_ONLN)) + "\n";

    uint64_t memsize;
    size_t len = sizeof(memsize);
    static int mib_s[2] = { CTL_HW, HW_MEMSIZE };
    if (sysctl (mib_s, 2, &memsize, &len, NULL, 0) == 0)
        total_ram += QString::number(memsize/1024/1024) + " MB\n";
    else
        total_ram += "Error getting total RAM information\n";

    int mib[] = {CTL_KERN, KERN_OSRELEASE};
    sysctl(mib, sizeof mib / sizeof(int), NULL, &len, NULL, 0);

    char *kernelVersion = (char *)malloc(sizeof(char)*len);
    sysctl(mib, sizeof mib / sizeof(int), kernelVersion, &len, NULL, 0);

    QString kernelVersionStr = QString(kernelVersion);
    free(kernelVersion);
    int major_version = kernelVersionStr.split(".").first().toUInt() - 4;
    int minor_version = kernelVersionStr.split(".").at(1).toUInt();
    os_version += QString("Mac OS X 10.%1.%2").arg(major_version).arg(minor_version) + " ";

    switch(major_version)
    {
        case 4:  os_version += "\"Tiger\"\n"; break;
        case 5:  os_version += "\"Leopard\"\n"; break;
        case 6:  os_version += "\"Snow Leopard\"\n"; break;
        case 7:  os_version += "\"Lion\"\n"; break;
        case 8:  os_version += "\"Mountain Lion\"\n"; break;
        default: os_version += "\"Unknown version\"\n"; break;
    }
#endif
#ifdef Q_WS_WIN
    SYSTEM_INFO sysinfo;
    GetSystemInfo(&sysinfo);
    number_of_cores += QString::number(sysinfo.dwNumberOfProcessors) + "\n";
    MEMORYSTATUSEX status;
    status.dwLength = sizeof(status);
    GlobalMemoryStatusEx(&status);
    total_ram += QString::number(status.ullTotalPhys);

    switch(QSysInfo::WinVersion())
    {
        case QSysInfo::WV_2000: os_version += "Windows 2000\n"; break;
        case QSysInfo::WV_XP: os_version += "Windows XP\n"; break;
        case QSysInfo::WV_VISTA: os_version += "Windows Vista\n"; break;
        case QSysInfo::WV_WINDOWS7: os_version += "Windows 7\n"; break;
        default: os_version += "Windows (Unknown version)\n"; break;
    }
    kernel_line += "Windows kernel\n";
#endif
#ifdef Q_WS_X11
    number_of_cores += QString::number(sysconf(_SC_NPROCESSORS_ONLN)) + "\n";
    long pages = sysconf(_SC_PHYS_PAGES),
#ifndef Q_OS_FREEBSD
         available_pages = sysconf(_SC_AVPHYS_PAGES),
#else
         available_pages = 0,
#endif
         page_size = sysconf(_SC_PAGE_SIZE);
    total_ram += QString::number(pages * page_size) + "\n";
    os_version += "GNU/Linux or BSD\n";
#endif

    // uname -a
#if defined(Q_WS_X11) || defined(Q_WS_MACX)
    QProcess *process = new QProcess();
    QStringList arguments = QStringList("-a");
    process->start("uname", arguments);
    if (process->waitForFinished())
        kernel_line += QString(process->readAll());
    delete process;
#endif

    // cpu info
    uint32_t registers[4];
    uint32_t i;

    i = 0x80000002;
    asm volatile
      ("cpuid" : "=a" (registers[0]), "=b" (registers[1]), "=c" (registers[2]), "=d" (registers[3])
       : "a" (i), "c" (0));
    processor_name += std::string((const char *)&registers[0], 4);
    processor_name += std::string((const char *)&registers[1], 4);
    processor_name += std::string((const char *)&registers[2], 4);
    processor_name += std::string((const char *)&registers[3], 4);
    i = 0x80000003;
    asm volatile
      ("cpuid" : "=a" (registers[0]), "=b" (registers[1]), "=c" (registers[2]), "=d" (registers[3])
       : "a" (i), "c" (0));
    processor_name += std::string((const char *)&registers[0], 4);
    processor_name += std::string((const char *)&registers[1], 4);
    processor_name += std::string((const char *)&registers[2], 4);
    processor_name += std::string((const char *)&registers[3], 4);
    i = 0x80000004;
    asm volatile
      ("cpuid" : "=a" (registers[0]), "=b" (registers[1]), "=c" (registers[2]), "=d" (registers[3])
       : "a" (i), "c" (0));
    processor_name += std::string((const char *)&registers[0], 4);
    processor_name += std::string((const char *)&registers[1], 4);
    processor_name += std::string((const char *)&registers[2], 4);
    processor_name += std::string((const char *)&registers[3], 3);

    // compiler
#ifdef __GNUC__
    compiler_version += "GCC " + QString(__VERSION__) + "\n";
#else
    compiler_version += "Unknown\n";
#endif

    if(sizeof(void*) == 4)
        compiler_bits += "i386\n";
    else if(sizeof(void*) == 8)
        compiler_bits += "x86_64\n";

    // add everything to the field of text
    description->setText(
        "\n\n\n\n\n"
        "System information:\n"
        + qt_version
        + os_version
        + total_ram
        + screen_size
        + number_of_screens
        + QString::fromStdString(processor_name + "\n")
        + number_of_cores
        + compiler_version
        + compiler_bits
        + kernel_line
    );
}

QNetworkAccessManager * PageFeedback::GetNetManager()
{
    if (netManager) return netManager;
    netManager = new QNetworkAccessManager(this);
    connect(netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(NetReply(QNetworkReply*)));
    return netManager;
}

void PageFeedback::LoadCaptchaImage()
{
        QNetworkAccessManager *netManager = GetNetManager();
        QUrl captchaURL("http://hedgewars.org/feedback/?gencaptcha");
        QNetworkRequest req(captchaURL);
        genCaptchaRequest = netManager->get(req);
}

void PageFeedback::NetReply(QNetworkReply *reply)
{
    if (reply == genCaptchaRequest)
    {
        if (reply->error() != QNetworkReply::NoError)
        {
            qDebug() << "Error generating captcha image: " << reply->errorString();
            ShowErrorMessage(QMessageBox::tr("Failed to generate captcha"));
            return;
        }

        bool okay;
        QByteArray body = reply->readAll();
        captchaID = QString(body).toInt(&okay);

        if (!okay)
        {
            qDebug() << "Failed to get captcha ID: " << body;
            ShowErrorMessage(QMessageBox::tr("Failed to generate captcha"));
            return;
        }

        QString url = "http://hedgewars.org/feedback/?captcha&id=";
        url += QString::number(captchaID);
        
        QNetworkAccessManager *netManager = GetNetManager();
        QUrl captchaURL(url);
        QNetworkRequest req(captchaURL);
        captchaImageRequest = netManager->get(req);
    }
    else if (reply == captchaImageRequest)
    {
        if (reply->error() != QNetworkReply::NoError)
        {
            qDebug() << "Error loading captcha image: " << reply->errorString();
            ShowErrorMessage(QMessageBox::tr("Failed to download captcha"));
            return;
        }

        QByteArray imageData = reply->readAll();
        QPixmap pixmap;
        pixmap.loadFromData(imageData);
        label_captcha->setPixmap(pixmap);
        captcha_code->setText("");
    }
}

QLayout * PageFeedback::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();
    QHBoxLayout * captchaLayout = new QHBoxLayout();
    QVBoxLayout * captchaInputLayout = new QVBoxLayout();

    label_captcha = new QLabel();
    label_captcha->setStyleSheet("border: 3px solid #ffcc00; border-radius: 4px");
    label_captcha->setText("<div style='width: 200px; height: 100px;'>loading<br>captcha</div>");
    captchaLayout->addWidget(label_captcha);

    label_captcha_input = new QLabel();
    label_captcha_input->setText(QLabel::tr("Type the security code:"));
    captchaInputLayout->addWidget(label_captcha_input);
    captchaInputLayout->setAlignment(label_captcha, Qt::AlignBottom);
    captcha_code = new QLineEdit();
    captcha_code->setFixedSize(165, 30);
    captchaInputLayout->addWidget(captcha_code);
    captchaInputLayout->setAlignment(captcha_code, Qt::AlignTop);
    captchaLayout->addLayout(captchaInputLayout);
    captchaLayout->setAlignment(captchaInputLayout, Qt::AlignLeft);

    captchaLayout->insertSpacing(-1, 40);
    bottomLayout->addLayout(captchaLayout);
    
    //TODO: create logo for send button
    BtnSend = addButton("Send Feedback", bottomLayout, 0, false);
    BtnSend->setFixedSize(120, 40);

    bottomLayout->setStretchFactor(captchaLayout, 0);
    bottomLayout->setStretchFactor(BtnSend, 1);

    return bottomLayout;
}

void PageFeedback::connectSignals()
{
    //TODO
}

void PageFeedback::ShowErrorMessage(const QString & msg)
{
    QMessageBox msgMsg(this);
    msgMsg.setIcon(QMessageBox::Warning);
    msgMsg.setWindowTitle(QMessageBox::tr("Hedgewars - Error"));
    msgMsg.setText(msg);
    msgMsg.setWindowModality(Qt::WindowModal);
    msgMsg.exec();
}

PageFeedback::PageFeedback(QWidget* parent) : AbstractPage(parent)
{
    initPage();
    netManager = NULL;
}
