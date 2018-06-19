/**
 * A plugin to enable placeholder tokens to be inserted into the CKEditor message. Use on its own or with teh placeholder plugin. 
 * The default format is compatible with the placeholders syntex
 *
 * @version 0.1 
 * @Author Troy Lutton
 * @license MIT 
 * 
 * This is a pure modification for the placeholders plugin. All credit goes to Stuart Sillitoe for creating the original (stuartsillitoe.co.uk)
 *
 */

CKEDITOR.plugins.add('placeholder_select',
{
	requires : ['richcombo'],
	init : function( editor )
	{
   for (var p = 0; p < editor.config.placeholder_selects.length; p++) {
		//  array of placeholders to choose from that'll be inserted into the editor
		var placeholders = [];
		
		// init the default config - empty placeholders
		var defaultConfig = {
			format: '#{%placeholder%}',
			placeholders : [],
			title: 'Select Placeholder',
			key: 'placeholder_select'
		};

		// merge defaults with the passed in items		
		var config = CKEDITOR.tools.extend(defaultConfig, editor.config.placeholder_selects[p] || {}, true);

		// run through an create the set of items to use
		for (var i = 0; i < config.placeholders.length; i++) {
			// get our potentially custom placeholder format
			// var value = config.placeholders[i].replace(/([A-Z])/g, function($1){return "_"+$1.toLowerCase();});

      var format = defaultConfig.format;

			if (config.placeholders[i].type == 'loop'){
				format = '[[ %placeholder%.each do | %iterator% | ]] <br /> [[ end ]]';
			}

			if (config.placeholders[i].type == 'condition'){
				format = '[[ if %placeholder% ]] <br /> [[ else ]] <br /> [[ end ]]';
			}


			var placeholder = format.replace('%placeholder%', config.placeholders[i].target);

			if (format.match(/%iterator%/g) != null) {
				placeholder = placeholder.replace('%iterator%', config.placeholders[i].iterator);
			}

			placeholders.push([placeholder, config.placeholders[i].title, config.placeholders[i].title]);
		}

		var title = config.title;


		// add the menu to the editor
		editor.ui.addRichCombo(config.key,
		{
			label: 		title,
			title: 		title,
			voiceLabel: title,
			placeholders: placeholders,
			className: 	'cke_format',
			multiSelect:false,
			panel:
			{
				css: [ editor.config.contentsCss, CKEDITOR.skin.getPath('editor') ],
				voiceLabel: editor.lang.panelVoiceLabel
			},

			init: function()
			{
				this.startGroup( this.title );

				for (var i in this.placeholders)
				{
					this.add(this.placeholders[i][0], this.placeholders[i][1], this.placeholders[i][2]);
				}
			},

			onClick: function( value )
			{
				editor.focus();
				editor.fire( 'saveSnapshot' );
				editor.insertHtml(value);
				editor.fire( 'saveSnapshot' );
			}
		});

    }
	}
});