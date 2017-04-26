#include <QDebug>
#include <QFile>
#include <QXmlStreamReader>


int main(int, char **)
{
    QFile file{"D:/dev/JUCE/examples/HelloWorld/HelloWorld.jucer"};
    file.open(QFile::ReadOnly);

    QXmlStreamReader reader{&file};

    auto depth = 0;
    QString xpath;

    while(!reader.atEnd()) {
        reader.readNext();

        if (reader.isStartElement()) {
            if (depth > 0) {
                xpath.append("/");
                xpath.append(reader.name());
            } else {
                xpath = reader.name().toString();
            }
            depth += 1;

            auto elm_attrs = reader.attributes();
            QString attrs;
            if (!elm_attrs.empty()) {
                attrs = "[TODO]";
            }

            qInfo() << xpath + attrs;
        }
        else if (reader.isEndElement()) {
            depth -= 1;
            auto lastSlashPos = xpath.lastIndexOf("/");
            xpath.resize(lastSlashPos);
        }
    }

    if (reader.hasError()) {
        qWarning() << reader.errorString();
    }

    return 0;
}
