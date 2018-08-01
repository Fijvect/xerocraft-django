# Generated by Django 2.0.3 on 2018-07-08 00:14

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('kmkr', '0005_auto_20180707_1409'),
    ]

    operations = [
        migrations.AlterField(
            model_name='playlogentry',
            name='radiodj_id',
            field=models.IntegerField(blank=True, help_text='The track ID of the item in the Radio DJ database.', null=True),
        ),
        migrations.AlterField(
            model_name='playlogentry',
            name='track',
            field=models.ForeignKey(blank=True, help_text='The track which was aired.', null=True, on_delete=django.db.models.deletion.PROTECT, to='kmkr.Track'),
        ),
        migrations.AlterField(
            model_name='track',
            name='radiodj_id',
            field=models.IntegerField(help_text='The track ID of the item in the Radio DJ database.', unique=True),
        ),
    ]