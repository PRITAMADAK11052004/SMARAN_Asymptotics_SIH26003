import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const cBg = Color(0xFFFFF6E3);
const cWhite = Color(0xFFFFFDFC);
const cPrimary = Color(0xFF18B981);
const cPrimaryDark = Color(0xFF4F743D);
const cDeep = Color(0xFF193C34);
const cSoft = Color(0xFFE5F0D8);
const cMint = Color(0xFFEEF4E7);
const cTeal = Color(0xFF2E7D68);
const cText = Color(0xFF26332E);
const cMuted = Color(0xFF6D746E);
const cBorder = Color(0xFFE6DED0);
const cDanger = Color(0xFFC64A4A);

void main() => runApp(const SmaranApp());

class SmaranApp extends StatefulWidget { const SmaranApp({super.key}); @override State<SmaranApp> createState()=>_SmaranAppState(); }
class _SmaranAppState extends State<SmaranApp> {
  late final SmaranStore store;
  bool ready=false;
  @override void initState(){super.initState(); store=SmaranStore(); _boot();}
  Future<void> _boot() async { await store.load(); if(mounted)setState(()=>ready=true); }
  @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Smaran',theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:cBg,colorScheme:ColorScheme.fromSeed(seedColor:cPrimary,brightness:Brightness.light),fontFamily:'sans-serif'),home:ready?SplashGate(store:store):const Scaffold(body:Center(child:CircularProgressIndicator(color:cPrimary))));
}

class SmaranStore {
  late SharedPreferences prefs;
  String patientName='Patient'; String caregiverName='Caregiver'; String language='English'; bool guardian=false;
  List<Reminder> reminders=[]; List<Person> people=[]; List<Memory> memories=[];
  Future<void> load() async {
    prefs=await SharedPreferences.getInstance(); patientName=prefs.getString('patientName')??'Patient'; caregiverName=prefs.getString('caregiverName')??'Caregiver'; language=prefs.getString('language')??'English'; guardian=prefs.getBool('guardian')??false;
    reminders=(jsonDecode(prefs.getString('reminders')??'[]') as List).map((e)=>Reminder.fromJson(e)).toList();
    people=(jsonDecode(prefs.getString('people')??'[]') as List).map((e)=>Person.fromJson(e)).toList();
    memories=(jsonDecode(prefs.getString('memories')??'[]') as List).map((e)=>Memory.fromJson(e)).toList();
  }
  Future<void> save() async { await prefs.setString('patientName',patientName); await prefs.setString('caregiverName',caregiverName); await prefs.setString('language',language); await prefs.setBool('guardian',guardian); await prefs.setString('reminders',jsonEncode(reminders.map((e)=>e.toJson()).toList())); await prefs.setString('people',jsonEncode(people.map((e)=>e.toJson()).toList())); await prefs.setString('memories',jsonEncode(memories.map((e)=>e.toJson()).toList())); }
}
class Reminder { String title,time,detail; bool done; Reminder({required this.title,required this.time,this.detail='',this.done=false}); Map<String,dynamic> toJson()=>{'title':title,'time':time,'detail':detail,'done':done}; factory Reminder.fromJson(Map e)=>Reminder(title:e['title']??'Reminder',time:e['time']??'08:00 AM',detail:e['detail']??'',done:e['done']??false); }
class Person { String name,relation; Person({required this.name,required this.relation}); Map<String,dynamic> toJson()=>{'name':name,'relation':relation}; factory Person.fromJson(Map e)=>Person(name:e['name']??'',relation:e['relation']??'Family'); }
class Memory { String title,path; Memory({required this.title,required this.path}); Map<String,dynamic> toJson()=>{'title':title,'path':path}; factory Memory.fromJson(Map e)=>Memory(title:e['title']??'Memory',path:e['path']??''); }

class SplashGate extends StatefulWidget { final SmaranStore store; const SplashGate({super.key,required this.store}); @override State<SplashGate> createState()=>_SplashGateState(); }
class _SplashGateState extends State<SplashGate>{ final player=AudioPlayer(); late Timer timer; double progress=0; @override void initState(){super.initState(); _start();} Future<void> _start() async { try{await player.setReleaseMode(ReleaseMode.loop); await player.play(AssetSource('audio/dhakk_beat.mp3'));}catch(_){ } int ticks=0; timer=Timer.periodic(const Duration(milliseconds:100),(t){if(!mounted)return; ticks++; setState(()=>progress=ticks/50); if(ticks>=50){t.cancel(); player.stop(); Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>LoginScreen(store:widget.store)));}}); } @override void dispose(){timer.cancel();player.dispose();super.dispose();} @override Widget build(BuildContext context)=>Scaffold(backgroundColor:cBg,body:Center(child:LayoutBuilder(builder:(c,box){final h=box.maxHeight; return Stack(alignment:Alignment.center,children:[Image.asset('assets/images/durga-puja-splash.png',fit:BoxFit.contain,width:box.maxWidth,height:h),Positioned(bottom:h*.23,child:Image.asset('assets/images/smaran-splash-icon.png',width:82,height:82)),Positioned(bottom:h*.12,child:SizedBox(width:92,height:92,child:CircularProgressIndicator(value:progress,strokeWidth:5,color:cPrimaryDark,backgroundColor:Colors.white54))),Positioned(bottom:h*.065,child:Text('Smaran',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,color:cDeep))),]);}))); }

class Logo extends StatelessWidget { final double size; const Logo({super.key,this.size=58}); @override Widget build(BuildContext context)=>Image.asset('assets/images/logo.png',width:size,height:size,fit:BoxFit.contain); }
InputDecoration inputDec(String label,{String? hint})=>InputDecoration(labelText:label,hintText:hint,filled:true,fillColor:cWhite,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:cBorder)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:cBorder)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:cPrimary,width:2)),contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:15));
Widget primaryButton(String text,VoidCallback? on,{IconData? icon})=>SizedBox(width:double.infinity,height:54,child:ElevatedButton.icon(onPressed:on,icon:Icon(icon??Icons.arrow_forward_rounded),label:Text(text,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),style:ElevatedButton.styleFrom(backgroundColor:cPrimaryDark,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)))));

class LoginScreen extends StatefulWidget { final SmaranStore store; const LoginScreen({super.key,required this.store}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen>{ final id=TextEditingController(text:''); final pass=TextEditingController(); bool show=false; String error=''; bool busy=false; Future<void> login() async {setState(()=>error=''); final v=id.text.trim(); if(v.isEmpty||pass.text.isEmpty){setState(()=>error='Enter your email/phone and password.');return;} if(v=='caregiver@smaran.app'&&pass.text=='Smaran123'||v==widget.store.caregiverName){setState(()=>busy=true);await Future.delayed(const Duration(milliseconds:500));if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>OnboardingOrHome(store:widget.store)));}else {
  setState(()=>error='Invalid credentials. Demo: caregiver@smaran.app / Smaran123');
} }
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(24,30,24,30),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Center(child:Logo(size:82)),const SizedBox(height:14),const Center(child:Text('Welcome back to Smaran',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:cDeep))),const SizedBox(height:8),const Center(child:Text('A gentle place for memories, routines and support.',textAlign:TextAlign.center,style:TextStyle(color:cMuted,fontSize:15))),const SizedBox(height:34),TextField(controller:id,keyboardType:TextInputType.emailAddress,decoration:inputDec('Email or phone')),const SizedBox(height:14),TextField(controller:pass,obscureText:!show,decoration:inputDec('Password').copyWith(suffixIcon:IconButton(onPressed:()=>setState(()=>show=!show),icon:Icon(show?Icons.visibility_off:Icons.visibility)))),if(error.isNotEmpty)...[const SizedBox(height:12),Text(error,style:const TextStyle(color:cDanger,fontWeight:FontWeight.w700))],const SizedBox(height:20),primaryButton(busy?'Signing in…':'Sign in',busy?null:login,icon:Icons.lock_open_rounded),const SizedBox(height:10),Center(child:TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ForgotScreen())),child:const Text('Forgot password?'))),const SizedBox(height:8),Center(child:TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SignupScreen(store:widget.store))),child:const Text('Create a new Smaran account'))),const SizedBox(height:25),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cMint,borderRadius:BorderRadius.circular(18)),child:const Text('Demo access\nEmail: caregiver@smaran.app\nPassword: Smaran123',style:TextStyle(color:cDeep,fontWeight:FontWeight.w700))),])))); }

class SignupScreen extends StatefulWidget { final SmaranStore store; const SignupScreen({super.key,required this.store}); @override State<SignupScreen> createState()=>_SignupScreenState(); }
class _SignupScreenState extends State<SignupScreen>{ final patient=TextEditingController(); final caregiver=TextEditingController(); final phone=TextEditingController(); final email=TextEditingController(); final pass=TextEditingController(); String relation='Adult Child'; String language='English'; Future<void> submit() async {if(patient.text.trim().isEmpty||caregiver.text.trim().isEmpty||pass.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please complete the required fields.')));return;} widget.store.patientName=patient.text.trim();widget.store.caregiverName=caregiver.text.trim();await widget.store.save();if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>BiometricScreen(store:widget.store)));} @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(backgroundColor:cBg,title:const Text('Create Account',style:TextStyle(fontWeight:FontWeight.w900)),leading:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back))),body:SingleChildScrollView(padding:const EdgeInsets.all(22),child:Column(children:[const Logo(size:70),const SizedBox(height:10),Text('Set up a caring Smaran profile',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900,color:cDeep)),const SizedBox(height:24),TextField(controller:patient,decoration:inputDec('Patient name *')),const SizedBox(height:13),TextField(controller:caregiver,decoration:inputDec('Caregiver name *')),const SizedBox(height:13),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:inputDec('Caregiver mobile')),const SizedBox(height:13),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:inputDec('Email')),const SizedBox(height:13),TextField(controller:pass,obscureText:true,decoration:inputDec('Password *')),const SizedBox(height:13),DropdownButtonFormField<String>(initialValue:relation,decoration:inputDec('Relationship'),items:['Spouse','Adult Child','Professional Nurse','Relative'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>relation=v!)),const SizedBox(height:13),DropdownButtonFormField<String>(initialValue:language,decoration:inputDec('Preferred language'),items:['English','বাংলা','हिन्दी','অসমীয়া'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>language=v!)),const SizedBox(height:24),primaryButton('Continue to security',submit,icon:Icons.security_rounded)])));
}

class BiometricScreen extends StatefulWidget { final SmaranStore store; const BiometricScreen({super.key,required this.store}); @override State<BiometricScreen> createState()=>_BiometricScreenState(); }
class _BiometricScreenState extends State<BiometricScreen>{bool busy=false;String msg='';Future<void> go() async {setState(()=>busy=true);try{final auth=LocalAuthentication();final ok=await auth.authenticate(localizedReason:'Secure your Smaran account');if(ok){await widget.store.save();if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>OnboardingScreen(store:widget.store)));}else {
  setState(()=>msg='Biometric verification was not completed.');
}}catch(e){setState(()=>msg='Biometric is unavailable on this device. You can continue for development.');}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(25),child:Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(28),border:Border.all(color:cBorder)),child:Column(children:[Container(width:78,height:78,decoration:const BoxDecoration(color:cSoft,shape:BoxShape.circle),child:const Icon(Icons.fingerprint_rounded,size:45,color:cPrimaryDark)),const SizedBox(height:20),const Text('Secure your Smaran account',textAlign:TextAlign.center,style:TextStyle(fontSize:27,fontWeight:FontWeight.w900,color:cDeep)),const SizedBox(height:10),const Text('Use your device fingerprint, face or other biometric to protect caregiver access.',textAlign:TextAlign.center,style:TextStyle(color:cMuted,fontSize:15)),if(msg.isNotEmpty)Padding(padding:const EdgeInsets.only(top:16),child:Text(msg,textAlign:TextAlign.center,style:const TextStyle(color:cDanger,fontWeight:FontWeight.w700))),const SizedBox(height:24),primaryButton(busy?'Verifying…':'Verify & continue',busy?null:go,icon:Icons.verified_user_rounded),const SizedBox(height:8),TextButton(onPressed:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>OnboardingScreen(store:widget.store))),child:const Text('Continue without biometric (development)'))]))))));}

class OnboardingOrHome extends StatelessWidget {final SmaranStore store;const OnboardingOrHome({super.key,required this.store});@override Widget build(BuildContext c)=>OnboardingScreen(store:store);}
class OnboardingScreen extends StatefulWidget {final SmaranStore store;const OnboardingScreen({super.key,required this.store});@override State<OnboardingScreen> createState()=>_OnboardingScreenState();}
class _OnboardingScreenState extends State<OnboardingScreen>{int i=0;final slides=[['Keep your people close','Save familiar faces, moments and stories in one gentle space.','Because familiar memories can make ordinary days feel warmer.',Icons.people_alt_rounded],['A little activity every day','Enjoy simple cognitive games designed for calm, comfortable practice.','Recall • Focus • Recognise • Smile',Icons.extension_rounded],['Support when you need it','Get reminders, helpful conversations and trusted connections from one app.','Private • Caring • Connected',Icons.favorite_rounded]];@override Widget build(BuildContext context){final s=slides[i];return Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('${i+1} / 3',style:const TextStyle(fontWeight:FontWeight.w800,color:cMuted)),const Logo(size:48)]),const SizedBox(height:20),LinearProgressIndicator(value:(i+1)/3,color:cPrimary,backgroundColor:cSoft,minHeight:7,borderRadius:BorderRadius.circular(10)),const Spacer(),Container(width:180,height:180,decoration:BoxDecoration(color:cMint,borderRadius: BorderRadius.circular(50)),child:Icon(s[3] as IconData,size:100,color:cPrimaryDark)),const SizedBox(height:30),Text(s[0] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:29,fontWeight:FontWeight.w900,color:cDeep)),const SizedBox(height:12),Text(s[1] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:16,color:cText,height:1.4)),const SizedBox(height:10),Text(s[2] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:14,color:cMuted)),const Spacer(),primaryButton(i==2?'Open Smaran':'Continue',()=>i==2?Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>Shell(store:widget.store))):setState(()=>i++),icon:i==2?Icons.home_rounded:Icons.arrow_forward_rounded)]))));}}

class Shell extends StatefulWidget {final SmaranStore store;const Shell({super.key,required this.store});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{String route='home';void nav(String r)=>setState(()=>route=r);@override Widget build(BuildContext context){Widget page;switch(route){case'family':page=FamilyScreen(store:widget.store);break;case'photos':page=PhotosScreen(store:widget.store);break;case'music':page=MusicScreen();break;case'relax':page=RelaxScreen();break;default:page=HomeScreen(store:widget.store,onNavigate:nav);}return Scaffold(body:SafeArea(child:page),bottomNavigationBar:BottomNav(active:route,onNavigate:nav));}}

class BottomNav extends StatelessWidget{final String active;final ValueChanged<String> onNavigate;const BottomNav({super.key,required this.active,required this.onNavigate});final items=const [('home','Home',Icons.home_rounded),('family','Family',Icons.people_alt_rounded),('photos','Photos',Icons.photo_library_rounded),('music','Music',Icons.music_note_rounded),('relax','Relax',Icons.water_drop_rounded)];@override Widget build(BuildContext c)=>Container(color:cBg,padding:const EdgeInsets.fromLTRB(12,5,12,9),child:Container(height:73,decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(23),border:Border.all(color:cBorder),boxShadow:[const BoxShadow(color:Color(0x1A7A694E),blurRadius:10,offset:Offset(0,3))]),child:Row(children:items.map((it){final sel=active==it.$1;return Expanded(child:InkWell(onTap:()=>onNavigate(it.$1),borderRadius:BorderRadius.circular(18),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:40,height:34,decoration:BoxDecoration(color:sel?const Color(0xFFF3E8CF):Colors.transparent,borderRadius:BorderRadius.circular(13)),child:Icon(it.$3,color:sel?cPrimaryDark:const Color(0xFF7E827B),size:21)),Text(it.$2,style:TextStyle(fontSize:10,fontWeight:sel?FontWeight.w900:FontWeight.w700,color:sel?cText:cMuted)),Container(width:18,height:3,margin:const EdgeInsets.only(top:3),decoration:BoxDecoration(color:sel?cPrimaryDark:Colors.transparent,borderRadius:BorderRadius.circular(2)))])));}).toList())));
}

class HomeScreen extends StatelessWidget {
  final SmaranStore store;
  final ValueChanged<String> onNavigate;
  const HomeScreen({super.key, required this.store, required this.onNavigate});
  String greeting() { final h=DateTime.now().hour; return h<12?'Good Morning':h<17?'Good Afternoon':'Good Evening'; }
  Widget card(BuildContext context,String icon,String title,String sub,Color color,String route) => InkWell(
    onTap: () => route=='games'||route=='reminders'||route=='talk'
      ? Navigator.push(context, MaterialPageRoute(builder:(_)=>FeatureRoute(store:store,route:route)))
      : onNavigate(route),
    borderRadius: BorderRadius.circular(20),
    child: Container(margin:const EdgeInsets.only(bottom:11),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(20),boxShadow:[const BoxShadow(color:Color(0x147A694E),blurRadius:10,offset:Offset(0,3))]),child:Row(children:[
      Container(width:56,height:56,decoration:BoxDecoration(color:Colors.white.withValues(alpha: .82),borderRadius:BorderRadius.circular(18)),child:Center(child:Text(icon,style:const TextStyle(fontSize:28)))),
      Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15.5,color:cText)),const SizedBox(height:4),Text(sub,style:const TextStyle(fontSize:11.5,color:cMuted))]))),
      const CircleAvatar(radius:17,backgroundColor:cWhite,child:Icon(Icons.chevron_right_rounded,color:cPrimaryDark,size:27))
    ])));
  @override Widget build(BuildContext context) {
    Widget action(String icon,String label,String route)=>InkWell(onTap:()=>route=='games'||route=='reminders'||route=='talk'?Navigator.push(context,MaterialPageRoute(builder:(_)=>FeatureRoute(store:store,route:route))):onNavigate(route),borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(18),border:Border.all(color:cBorder)),child:Column(children:[Text(icon,style:const TextStyle(fontSize:25)),const SizedBox(height:5),Text(label,style:const TextStyle(fontWeight:FontWeight.w800,color:cText))])));
    return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,12,18,20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Logo(size:52),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('SMARAN',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900,letterSpacing:2,color:cPrimaryDark)),Text(greeting(),style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:cDeep))])),IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProfileScreen(store:store))),icon:const Icon(Icons.person_outline_rounded,size:30,color:cDeep))]),
      const SizedBox(height:16),
      Container(width:double.infinity,padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:cDeep,borderRadius:BorderRadius.circular(25)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Hello,',style:TextStyle(color:cMint,fontSize:14)),Text(store.patientName,style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Let’s make today calm, familiar and meaningful.',style:TextStyle(color:Color(0xFFD8E9DE),fontSize:13,height:1.35))])),const CircleAvatar(radius:38,backgroundColor:cSoft,child:Icon(Icons.favorite_rounded,size:40,color:cPrimaryDark))])),
      const SizedBox(height:20),const Text('Your Smaran space',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:cDeep)),const SizedBox(height:10),
      card(context,'✦','Your Daily Task','Cognitive Memory Game',cSoft,'games'),card(context,'☁','Memory Garden','Memory Assistant',const Color(0xFFF6DCDD),'talk'),card(context,'🛤','Memory Lane','Your Past Memories',const Color(0xFFDCECF2),'photos'),card(context,'🗓','Scheduled','Your Daily Routine',const Color(0xFFF5E6C7),'reminders'),
      const SizedBox(height:4),Row(children:[Expanded(child:action('🧠','Games','games')),const SizedBox(width:10),Expanded(child:action('⏰','Reminders','reminders'))]),const SizedBox(height:10),Row(children:[Expanded(child:action('💬','Talking Help','talk')),const SizedBox(width:10),Expanded(child:action('👨‍👩‍👧','Family','family'))])
    ]));
  }
}

class FeatureRoute extends StatelessWidget {
  final SmaranStore store; final String route;
  const FeatureRoute({super.key,required this.store,required this.route});
  @override Widget build(BuildContext c){
    final Widget w=switch(route){'games'=>GamesScreen(store:store),'reminders'=>RemindersScreen(store:store),'talk'=>TalkingScreen(store:store),_=>HomeScreen(store:store,onNavigate:(_){})};
    return Scaffold(appBar:AppBar(backgroundColor:cBg,title:Text(route[0].toUpperCase()+route.substring(1),style:const TextStyle(fontWeight:FontWeight.w900))),body:SafeArea(child:w));
  }
}

class PageHeader extends StatelessWidget { final String title,subtitle; const PageHeader({super.key,required this.title,this.subtitle=''}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(18,10,18,12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:cDeep)),if(subtitle.isNotEmpty)Text(subtitle,style:const TextStyle(color:cMuted))])); }

class RemindersScreen extends StatefulWidget { final SmaranStore store; const RemindersScreen({super.key,required this.store}); @override State<RemindersScreen> createState()=>_RemindersScreenState(); }
class _RemindersScreenState extends State<RemindersScreen>{
  Future<void> add() async { final t=TextEditingController(),time=TextEditingController(text:'08:00 AM'),d=TextEditingController(); await showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Add reminder'),content:SingleChildScrollView(child:Column(children:[TextField(controller:t,decoration:inputDec('Task')),const SizedBox(height:10),TextField(controller:time,decoration:inputDec('Time',hint:'08:00 AM')),const SizedBox(height:10),TextField(controller:d,decoration:inputDec('Notes'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),ElevatedButton(onPressed:(){if(t.text.trim().isNotEmpty){setState(()=>widget.store.reminders.add(Reminder(title:t.text.trim(),time:time.text.trim(),detail:d.text.trim())));widget.store.save();Navigator.pop(c);}},child:const Text('Save'))])); }
  @override Widget build(BuildContext context){ return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,0,18,20),child:Column(children:[PageHeader(title:'Daily Routine',subtitle:'Gentle reminders for familiar routines.'),Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:add,icon:const Icon(Icons.add),label:const Text('Add reminder'))),const SizedBox(height:12),if(widget.store.reminders.isEmpty)Container(width:double.infinity,padding:const EdgeInsets.all(25),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(20),border:Border.all(color:cBorder)),child:const Column(children:[Icon(Icons.schedule_rounded,size:45,color:cPrimaryDark),SizedBox(height:8),Text('No reminders yet',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),Text('Add a meal, medicine, walk or other daily task.',textAlign:TextAlign.center,style:TextStyle(color:cMuted))])) else ...widget.store.reminders.asMap().entries.map((e)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(20),border:Border.all(color:cBorder)),child:Row(children:[Checkbox(value:e.value.done,onChanged:(v){setState(()=>e.value.done=v??false);widget.store.save();}),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e.value.title,style:TextStyle(fontWeight:FontWeight.w900,fontSize:17,decoration:e.value.done?TextDecoration.lineThrough:null)),Text(e.value.time,style:const TextStyle(color:cPrimaryDark,fontWeight:FontWeight.w800)),if(e.value.detail.isNotEmpty)Text(e.value.detail,style:const TextStyle(color:cMuted))])),IconButton(onPressed:(){setState(()=>widget.store.reminders.removeAt(e.key));widget.store.save();},icon:const Icon(Icons.delete_outline,color:cDanger))])))])); }
}

class GamesScreen extends StatefulWidget {
  final SmaranStore store;
  const GamesScreen({super.key, required this.store});
  @override State<GamesScreen> createState()=>_GamesScreenState();
}
class _GamesScreenState extends State<GamesScreen>{
  int score=0; String message='Choose a gentle activity to begin.';
  final games=[['🧠','Memory Match','Match familiar pairs and exercise recall.'],['123','Daily Recall','Remember a short sequence.'],['🔎','Find the Difference','Focus on small visual details.'],['🌸','Word & Picture','Connect familiar words and images.']];
  void play(int i){setState((){message='Great! You completed ${games[i][1]}. Your daily practice is recorded locally.';score++;});}
  @override Widget build(BuildContext c){
    return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,0,18,20),child:Column(children:[
      PageHeader(title:'Cognitive Games',subtitle:'Calm, simple activities for recall and focus.'),
      Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:cDeep,borderRadius:BorderRadius.circular(22)),child:Row(children:[const Icon(Icons.stars_rounded,color:cSoft,size:38),const SizedBox(width:14),Expanded(child:Text('Today: $score / 5 activities',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:18)))])),
      const SizedBox(height:15),
      ...games.asMap().entries.map((e){return InkWell(onTap:()=>play(e.key),borderRadius:BorderRadius.circular(20),child:Container(margin:const EdgeInsets.only(bottom:11),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(20),border:Border.all(color:cBorder)),child:Row(children:[Text(e.value[0],style:const TextStyle(fontSize:32)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e.value[1],style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:cText)),const SizedBox(height:4),Text(e.value[2],style:const TextStyle(color:cMuted))])),const Icon(Icons.play_circle_fill_rounded,color:cPrimaryDark,size:34)])));}),
      Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cMint,borderRadius:BorderRadius.circular(18)),child:Text(message,style:const TextStyle(color:cDeep,fontWeight:FontWeight.w700)))
    ]));
  }
}

class PhotosScreen extends StatefulWidget { final SmaranStore store; const PhotosScreen({super.key,required this.store}); @override State<PhotosScreen> createState()=>_PhotosScreenState(); }
class _PhotosScreenState extends State<PhotosScreen>{
  final picker=ImagePicker();
  Future<void> add()async{final x=await picker.pickImage(source:ImageSource.gallery,imageQuality:85);if(x==null)return;setState(()=>widget.store.memories.add(Memory(title:'A familiar memory',path:x.path)));await widget.store.save();}
  @override Widget build(BuildContext c){
    return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,0,18,20),child:Column(children:[
      PageHeader(title:'Memory Garden',subtitle:'Keep familiar moments close.'),
      Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:add,icon:const Icon(Icons.add_photo_alternate_rounded),label:const Text('Add memory'))),
      const SizedBox(height:12),
      if(widget.store.memories.isEmpty)
        Container(width:double.infinity,padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(22),border:Border.all(color:cBorder)),child:const Column(children:[Icon(Icons.photo_library_outlined,size:52,color:cPrimaryDark),SizedBox(height:10),Text('Your Memory Garden is empty',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),Text('Add familiar photos from the phone gallery.',textAlign:TextAlign.center,style:TextStyle(color:cMuted))]))
      else
        GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.9),itemCount:widget.store.memories.length,itemBuilder:(context,index){
          final m=widget.store.memories[index];
          return Container(clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(18),border:Border.all(color:cBorder)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Image.file(File(m.path),fit:BoxFit.cover,width:double.infinity,errorBuilder:(_,_,_)=>const Center(child:Icon(Icons.broken_image)))),Padding(padding:const EdgeInsets.all(10),child:Text(m.title,style:const TextStyle(fontWeight:FontWeight.w800)))]));
        })
    ]));
  }
}

class FamilyScreen extends StatefulWidget { final SmaranStore store; const FamilyScreen({super.key,required this.store}); @override State<FamilyScreen> createState()=>_FamilyScreenState(); }
class _FamilyScreenState extends State<FamilyScreen>{
  Future<void> add()async{final n=TextEditingController(),r=TextEditingController(text:'Family');await showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Add trusted person'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:inputDec('Name')),const SizedBox(height:10),TextField(controller:r,decoration:inputDec('Relationship'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),ElevatedButton(onPressed:(){if(n.text.isNotEmpty){setState(()=>widget.store.people.add(Person(name:n.text.trim(),relation:r.text.trim())));widget.store.save();Navigator.pop(c);}},child:const Text('Save'))]));}
  @override Widget build(BuildContext c){return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,0,18,20),child:Column(children:[PageHeader(title:'Family Circle',subtitle:'People who help make Smaran feel familiar.'),Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:add,icon:const Icon(Icons.person_add_rounded),label:const Text('Add person'))),const SizedBox(height:12),...widget.store.people.map((p)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(20),border:Border.all(color:cBorder)),child:Row(children:[const CircleAvatar(backgroundColor:cSoft,child:Icon(Icons.person,color:cPrimaryDark)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),Text(p.relation,style:const TextStyle(color:cMuted))])),IconButton(onPressed:(){setState(()=>widget.store.people.remove(p));widget.store.save();},icon:const Icon(Icons.delete_outline,color:cDanger))]))),if(widget.store.people.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Text('No trusted people added yet.',style:TextStyle(color:cMuted)))]));}
}

class TalkingScreen extends StatefulWidget {
  final SmaranStore store;
  const TalkingScreen({super.key,required this.store});
  @override State<TalkingScreen> createState()=>_TalkingScreenState();
}
class _TalkingScreenState extends State<TalkingScreen>{
  final input=TextEditingController();
  final tts=FlutterTts();
  final msgs=<Map<String,String>>[{'who':'Smaran','text':'Hello! I am here with you. You can ask about your reminders or simply talk to me.'}];
  Future<void> send()async{final q=input.text.trim();if(q.isEmpty)return;setState((){msgs.add({'who':'You','text':q});input.clear();});String a='I am here to help. Let’s take one step at a time.';final l=q.toLowerCase();if(l.contains('reminder')||l.contains('medicine')){a=widget.store.reminders.isEmpty?'You have no saved reminders yet.':'Your next saved routine is ${widget.store.reminders.first.title} at ${widget.store.reminders.first.time}.';}else if(l.contains('name')){a='Your Smaran profile is for ${widget.store.patientName}.';}setState(()=>msgs.add({'who':'Smaran','text':a}));try{await tts.setLanguage('en-IN');await tts.speak(a);}catch(_){}}
  @override void dispose(){input.dispose();tts.stop();super.dispose();}
  Widget message(Map<String,String> m){
    final me=m['who']=='You';
    return Align(
      alignment:me?Alignment.centerRight:Alignment.centerLeft,
      child:Container(
        margin:const EdgeInsets.only(bottom:10),
        padding:const EdgeInsets.all(14),
        constraints:const BoxConstraints(maxWidth:330),
        decoration:BoxDecoration(color:me?cPrimaryDark:cWhite,borderRadius:BorderRadius.circular(18),border:Border.all(color:me?cPrimaryDark:cBorder)),
        child:Text(m['text']!,style:TextStyle(color:me?Colors.white:cText,height:1.35)),
      ),
    );
  }
  @override Widget build(BuildContext c){final list=msgs.map(message).toList();return Column(children:[Expanded(child:ListView(padding:const EdgeInsets.all(18),children:list)),Container(padding:const EdgeInsets.fromLTRB(12,8,12,10),color:cBg,child:Row(children:[Expanded(child:TextField(controller:input,decoration:inputDec('Talk to Smaran',hint:'Ask about a reminder…'))),const SizedBox(width:8),CircleAvatar(backgroundColor:cPrimaryDark,child:IconButton(onPressed:send,icon:const Icon(Icons.send_rounded,color:Colors.white)))]))]);}
}

class MusicScreen extends StatefulWidget{const MusicScreen({super.key});@override State<MusicScreen> createState()=>_MusicScreenState();}
class _MusicScreenState extends State<MusicScreen>{bool playing=false;final p=AudioPlayer();Future<void> toggle()async{if(playing){await p.stop();setState(()=>playing=false);}else{try{await p.setReleaseMode(ReleaseMode.loop);await p.play(AssetSource('audio/dhakk_beat.mp3'));setState(()=>playing=true);}catch(_){}}}@override void dispose(){p.dispose();super.dispose();}@override Widget build(BuildContext c)=>SimpleFeature(title:'Music',subtitle:'Familiar sounds for a calm moment.',icon:Icons.music_note_rounded,child:Column(children:[const Text('Gentle audio can be part of a familiar daily routine.',textAlign:TextAlign.center,style:TextStyle(color:cMuted,fontSize:16)),const SizedBox(height:22),Container(width:150,height:150,decoration:const BoxDecoration(color:cSoft,shape:BoxShape.circle),child:const Icon(Icons.music_note_rounded,size:80,color:cPrimaryDark)),const SizedBox(height:22),primaryButton(playing?'Stop dhak beat':'Play dhak beat',toggle,icon:playing?Icons.stop_rounded:Icons.play_arrow_rounded)]));}
class RelaxScreen extends StatefulWidget{const RelaxScreen({super.key});@override State<RelaxScreen> createState()=>_RelaxScreenState();}
class _RelaxScreenState extends State<RelaxScreen> with SingleTickerProviderStateMixin{late final AnimationController controller;@override void initState(){super.initState();controller=AnimationController(vsync:this,duration:const Duration(seconds:3),lowerBound:.75,upperBound:1)..repeat(reverse:true);}@override void dispose(){controller.dispose();super.dispose();}@override Widget build(BuildContext c)=>SimpleFeature(title:'Relax',subtitle:'Slow down and breathe.',icon:Icons.water_drop_rounded,child:Column(children:[const Text('Take a comfortable breath in… and slowly breathe out.',textAlign:TextAlign.center,style:TextStyle(fontSize:18,color:cText,height:1.5)),const SizedBox(height:30),AnimatedBuilder(animation:controller,builder:(c,_)=>Container(width:160*controller.value,height:160*controller.value,decoration:const BoxDecoration(color:cSoft,shape:BoxShape.circle),child:const Icon(Icons.air_rounded,size:70,color:cPrimaryDark))),const SizedBox(height:25),const Text('There is no rush.',style:TextStyle(color:cMuted,fontWeight:FontWeight.w800))]));}
class SimpleFeature extends StatelessWidget{final String title,subtitle;final IconData icon;final Widget child;const SimpleFeature({super.key,required this.title,required this.subtitle,required this.icon,required this.child});@override Widget build(BuildContext c)=>SingleChildScrollView(padding:const EdgeInsets.all(22),child:Column(children:[PageHeader(title:title,subtitle:subtitle),const SizedBox(height:25),Container(width:double.infinity,padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:cWhite,borderRadius:BorderRadius.circular(26),border:Border.all(color:cBorder)),child:Column(children:[CircleAvatar(radius:45,backgroundColor:cSoft,child:Icon(icon,size:48,color:cPrimaryDark)),const SizedBox(height:25),child]))]));}
class ProfileScreen extends StatefulWidget{final SmaranStore store;const ProfileScreen({super.key,required this.store});@override State<ProfileScreen> createState()=>_ProfileScreenState();}
class _ProfileScreenState extends State<ProfileScreen>{
  late TextEditingController p,c; late String lang;
  @override void initState(){super.initState();p=TextEditingController(text:widget.store.patientName);c=TextEditingController(text:widget.store.caregiverName);lang=widget.store.language;}
  @override void dispose(){p.dispose();c.dispose();super.dispose();}
  Future<void> save()async{widget.store.patientName=p.text.trim().isEmpty?'Patient':p.text.trim();widget.store.caregiverName=c.text.trim().isEmpty?'Caregiver':c.text.trim();widget.store.language=lang;await widget.store.save();if(mounted)Navigator.pop(context);}
  @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:const Text('Profile',style:TextStyle(fontWeight:FontWeight.w900)),backgroundColor:cBg),body:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(children:[const Logo(size:75),const SizedBox(height:15),TextField(controller:p,decoration:inputDec('Patient name')),const SizedBox(height:12),TextField(controller:c,decoration:inputDec('Caregiver name')),const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:lang,decoration:inputDec('Language'),items:['English','বাংলা','हिन्दी','অসমীয়া'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>lang=v!)),const SizedBox(height:14),SwitchListTile(title:const Text('Guardian mode',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('Keep caregiver-oriented controls enabled.'),value:widget.store.guardian,onChanged:(v){setState(()=>widget.store.guardian=v);widget.store.save();}),const SizedBox(height:18),primaryButton('Save profile',save,icon:Icons.save_rounded)])));}
}
class ForgotScreen extends StatefulWidget{const ForgotScreen({super.key});@override State<ForgotScreen> createState()=>_ForgotScreenState();}
class _ForgotScreenState extends State<ForgotScreen>{final x=TextEditingController();String msg='';@override void dispose(){x.dispose();super.dispose();}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:cBg,title:const Text('Password recovery',style:TextStyle(fontWeight:FontWeight.w900))),body:Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Logo(size:70),const SizedBox(height:20),const Text('Forgot your password?',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:cDeep)),const SizedBox(height:12),TextField(controller:x,decoration:inputDec('Email or phone')),const SizedBox(height:20),primaryButton('Start recovery',(){setState(()=>msg='If the account exists, recovery instructions will be sent to the registered contact.');}),if(msg.isNotEmpty)Padding(padding:const EdgeInsets.only(top:20),child:Text(msg,textAlign:TextAlign.center,style:const TextStyle(color:cPrimaryDark,fontWeight:FontWeight.w700)))])));}
