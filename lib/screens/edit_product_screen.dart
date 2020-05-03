import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product.dart';
import '../providers/products_provider.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = "/edit-product";
  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  final _imageUrlFocusNode = FocusNode();
  var _form = GlobalKey<FormState>();
  var _editedDetails =
      Product(description: "", id: null, price: 0, title: "", imageUrl: "");
  var _isLoading = false;
  var _isInit = true;
  var _initValue = {
    "description": "",
    "title": "",
    "price": "",
    "imageUrl": "",
  };

  @override
  void initState() {
    _imageUrlFocusNode.addListener(_updateImageUrl);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      var prodId = ModalRoute.of(context).settings.arguments as String;

      if (prodId != null) {
        _editedDetails = Provider.of<ProductsProvider>(context, listen: false)
            .findById(prodId);
        print(_editedDetails.id);
        _initValue = {
          "description": _editedDetails.description,
          "title": _editedDetails.title,
          "imageUrl": "",
          "price": _editedDetails.price.toString(),
        };
        _imageUrlController.text = _editedDetails.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

//dispose the focusNode, so that it wont stick around in the memory and cause memory leak
  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    super.dispose();
  }

  void _updateImageUrl() {
    if (!_imageUrlFocusNode.hasFocus) {
      setState(() {});
    }
  }

  Future<void> _saveForm() async {
    var isValid = _form.currentState.validate();
    if (!isValid) {
      return;
    }
    _form.currentState.save();
    setState(() {
      _isLoading = true;
    });

    if (_editedDetails.id != null) {
      Provider.of<ProductsProvider>(context, listen: false)
          .updateProduct(_editedDetails.id, _editedDetails);
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();
    } else {
      try {
        await Provider.of<ProductsProvider>(context, listen: false)
            .addProduct(_editedDetails);
      } catch (error) {
        await showDialog<Null>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text("An error occured !"),
                  content: Text("Something went wrong !"),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Okay'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    )
                  ],
                ));
      } finally {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              child: Form(
                key: _form,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      initialValue: _initValue["title"],
                      decoration: InputDecoration(labelText: "Title"),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a value.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedDetails = Product(
                          imageUrl: _editedDetails.imageUrl,
                          title: value,
                          price: _editedDetails.price,
                          description: _editedDetails.description,
                          id: _editedDetails.id,
                          isFavorite: _editedDetails.isFavorite,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initValue["price"],
                      decoration: InputDecoration(labelText: "Price"),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode);
                      },
                      onSaved: (value) {
                        _editedDetails = Product(
                          imageUrl: _editedDetails.imageUrl,
                          title: _editedDetails.title,
                          price: double.parse(value),
                          description: _editedDetails.description,
                          id: _editedDetails.id,
                          isFavorite: _editedDetails.isFavorite,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initValue["description"],
                      decoration: InputDecoration(labelText: "Description"),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                      onSaved: (value) {
                        _editedDetails = Product(
                          imageUrl: _editedDetails.imageUrl,
                          title: _editedDetails.title,
                          price: _editedDetails.price,
                          description: value,
                          id: _editedDetails.id,
                          isFavorite: _editedDetails.isFavorite,
                        );
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                            height: 100,
                            width: 100,
                            margin: EdgeInsets.only(top: 8, right: 10),
                            decoration: BoxDecoration(
                                border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            )),
                            child: _imageUrlController.text.isEmpty
                                ? Text("Enter URL")
                                : FittedBox(
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.cover,
                                    ),
                                  )),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: "Image Url"),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            focusNode: _imageUrlFocusNode,
                            controller: _imageUrlController,
                            onFieldSubmitted: (_) {
                              _saveForm();
                            },
                            onSaved: (value) {
                              _editedDetails = Product(
                                imageUrl: value,
                                title: _editedDetails.title,
                                price: _editedDetails.price,
                                description: _editedDetails.description,
                                id: _editedDetails.id,
                                isFavorite: _editedDetails.isFavorite,
                              );
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              padding: EdgeInsets.all(15.0),
            ),
    );
  }
}
